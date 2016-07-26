# encoding: utf-8

#Monkey patch for WIN32OLE class
#-Define dummy class for Linux
#-Modification bihavior for ole_free method. FIXME: внешнее соединение с ИБ
# остается
# активным пока существует хотябы один объект порожденный этим соединением.
# Объекты могут пораждать другие объекты и т.д. Ссылки на объекты могут
# находиться как на строне Ruby так и на строне 1С. Теоретически если на стороне
# Ruby держать все ссылки на объекты и вызвать для них ole_free соеденинение
# должно закрыться. Но 1С объекты могут ссылаться на другие объекты тогда
# ole_free для бъекта на которого есть ссылки на строне 1С не сработает.
class WIN32OLE
  if AssLauncher::Support::Platforms.linux?
    class << self
      define_method(:new) do |*args|
        fail NotImplementedError, 'WIN32OLE undefined for this machine'
      end
    end
  else
    require 'win32ole'

    # Hold created Ole objects
    def __objects__
       @__objects__ ||= []
    end

    def __ruby__?
      ole_respond_to? :object_id
    end

    def __real_obj__
      return self unless __ruby__?
      ObjectSpace._id2ref(invoke :object_id)
    end

    # Free created chiled Ole objects then free self
    def __ass_ole_free__
      @__objects__ = __ass_ole_free_objects__
      self.class.__ass_ole_free__(self)
    end
    private :__ass_ole_free__

    # Free created chiled Ole objects
    def __ass_ole_free_objects__
      __objects__.each do |o|
        o.send :__ass_ole_free__ if o.is_a? WIN32OLE
      end
      nil
    end
    private :__ass_ole_free_objects__

    # Free Ole object
    # @parm obj [WIN32OLE] object for free
    def self.__ass_ole_free__(obj)
     return if WIN32OLE.ole_reference_count(obj) <= 0
     obj.ole_free
     # FIXME: IT NOT WORK. IT FAIL:
     #WIN32OLE.ole_reference_count(obj).times.each do |i|
     #   WIN32OLE.ole_free obj
     #end
    end

    old_method_missing = instance_method(:method_missing)
    # Overide method {WIN32OLE#method_missing} and hold Ole object into
    # {#__objects__} array if called Ole method return Ole object
    define_method(:method_missing) do |*args|
      o = old_method_missing.bind(self).(*args)
      __objects__ << o if o.is_a? WIN32OLE
      o
    end
  end
end

module AssLauncher
  module Enterprise
    # 1C:Enterprise ole objects layer
    module Ole
      class IbConnection
        attr_reader :__ole__
        def initialize(requirement)
          @requirement = requirement.to_s
        end

        def __version__
          @__version__ = __ole_binary__.version
        end

        def __open__(conn_str)
          return true if __opened__?
          __init_ole__(__ole_binary__.ole.connect(__cs__(conn_str)))
          true
        end

        def __init_ole__(ole)
          @__ole__ = ole
        end
        private :__init_ole__

        # @note It work not correct. It is not guaranteed to close connection.
        # FIXME: translate: соединение с ИБ останется активным
        # если будет существовать хотябы одна ссылка на ole объект порожденный
        # соединение. Вызов {#__ass_ole_free__} попытается вызват {#ole_free}
        # для всех ссылок но это работает не всегда.
        def __close__
          return if __closed__?
          @__ole__.send :__ass_ole_free__
          @__ole__ = nil
        end

        def __closed__?
          __ole__.nil?
        end

        def __opened__?
          !__closed__?
        end

        def __configure_com_connector__(**opts)
          opts.each do |k, v|
            __ole_binary__.ole.setproperty(k, v)
          end
        end

        def __cs__(conn_str)
          return conn_str.to_ole_string if conn_str.respond_to? :to_ole_string
          conn_str.to_s
        end
        protected :__cs__

        def __ole_binary__
          @__ole_binary__ ||= OleBinaries::COMConnector.new(@requirement)
        end

        def method_missing(method, *args)
          fail "Attempt call method for closed object #{self.class.name}"\
            if __closed__?
          o = __ole__.send(method, *args);
          o
        end
        protected :method_missing
      end

      # IWorkingProcessConnection
      class WpConnection < IbConnection
        def __open__(uri)
          return true if __opened__?
          __init_ole__(__ole_binary__.connectworkingprocess(uri.to_s))
          true
        end
      end

      # Wrapper for IServerAgentConnection
      class AgentConnection < IbConnection
        def __open__(uri)
          return true if __opened__?
          __init_ole__(__ole_binary__.ole.connectagent(uri.to_s))
          true
        end
      end

      class ApplicationConnectError < StandardError; end

      # Wrapper for V8xc.Application ole object
      class ThinApplication < IbConnection
        # Array of objects with opened connection for close all
        def self.objects
          @@objects ||= []
        end

        # Close all opened connectons
        def self.close_all
          objects.each do |o|
            o.__close__
          end
        end

        def initialize(requirement)
          super
          @opened = false
        end

        # Open connection in to infobase describe in conn_str
        def __open__(conn_str)
          return true if __opened__?
          begin
            @opened = __ole_binary__.ole.connect(__cs__(conn_str))
            fail ApplicationConnectError unless __opened__?
          rescue Exception => e
            @opened = false
            @__ole_binary__ = nil
            fail e
          end
          ThinApplication.objects << self
          __opened__?
        end

        def __ole__
          __ole_binary__.ole
        end

        def __opened__?
          @opened
        end

        def __closed__?
          !__opened__?
        end

        def __close__
          return true if __closed__?
          begin
    #       __ole__.visible = false
            __ole__.terminate
          rescue
          ensure
            # __ole__.send :__ass_ole_free__
            #__ole__.ole_free
            @__ole_binary__ = nil
            @opened = false
            ThinApplication.objects.delete(self)
          end
          true
        end

        def __ole_binary__
          @__ole_binary__ ||= OleBinaries::ThinApplication.new(@requirement)
        end
      end

      # Wrapper for V8x.Application ole object
      class ThickApplication < ThinApplication
        def __ole_binary__
          @__ole_binary__ ||= OleBinaries::ThickApplication.new(@requirement)
        end
      end

      module OleBinaries
        # @abstract
        class AbstractAssOleBinary
          include AssLauncher::Support::Platforms
          attr_reader :requirement
          def initialize(requirement)
            fail NotImplementedError, 'WIN32OLE undefined for this machine'\
              if linux?
            @requirement = Gem::Version::Requirement.new(requirement)
          end

          def version
            instaled_version
          end

          def ole
            @ole ||= new_ole
          end

          def new_ole
            reg
            WIN32OLE.new(prog_id)
          end

          def v8x
            version.to_s.split('.').slice(0,2).join('')
          end
          private :v8x

          def instaled_version
            return binary_wrapper.version if binary_wrapper
          end

          def binary_wrapper
            @binary_wrapper ||= get_binary_wrapper
          end

          def get_binary_wrapper
            fail 'Abstract method call'
          end
          private :get_binary_wrapper

          def registred_version
            fail 'FIXME'
          end

          def instaled?
            return false unless version
            requirement.satisfied_by?(version) &&\
              File.file?(path.to_s)
          end

          def registred?
            #FIXME: пока всегда регестрируем и не роемся в реестре registred_version == version
            false #FIXME
          end

          def reg
            return true if registred?
            fail "Platform version `#{requirement}' not instaled."\
              unless instaled?
            reg_server
          end

          def reg_server
            faisl 'Abstract method call'
          end
          private :reg_server

          def unreg
            return true unless registred?
            fail 'FIXME' unless instaled?
            unreg_server
          end

          def unreg_server
            faisl 'Abstract method call'
          end
          private :unreg_server

          def path
            @path ||= get_path
          end

          def get_path
            return unless binary_wrapper
            platform.path(File.join(binary_wrapper.path.dirname.to_s,binary))
          end
          private :get_path

          def clsid
            clsids[v8x]
          end

          def clsids
            fail 'Abstract method call'
          end
        end

        class COMConnector < AbstractAssOleBinary
          BINARY = 'comcntr.dll'
          def binary
            BINARY
          end

          def prog_id
            "v#{v8x}.COMConnector"
          end

          def clsids
            {'83' => '{181E893D-73A4-4722-B61D-D604B3D67D47}',
             '82' => '{2B0C1632-A199-4350-AA2D-2AEE3D2D573A}',
             '81' => '{48EE4DBA-DE11-4af2-83B9-1F7FD6B6B3E3}'
            }
          end

          def get_binary_wrapper
            Enterprise.thick_clients(requirement.to_s).last
          end
          private :get_binary_wrapper

          # @note It work not correct. If old version ole object is loded in
          # memory new registred version will be ignored.
          def reg_server
            `regsvr32 /i /s "#{path.win_string}"`
            fail "Failure register `#{path.win_string}' #{$?.to_s}"\
              unless $?.success?
          end
          private :reg_server

          def unreg_server
            `regsvr32 /u /s "#{path.win_string}"`
            fail "Failure register `#{path.win_string}' #{$?.to_s}"\
              unless $?.success?
          end
          private :unreg_server

        end

        class ThickApplication < AbstractAssOleBinary
          BINARY = '1cv8.exe'
          def binary
            BINARY
          end

          def prog_id
            "v#{v8x}.Application"
          end

          def get_binary_wrapper
            Enterprise.thick_clients(requirement.to_s).last
          end
          private :get_binary_wrapper

          def reg_server
            run_as_enterprise ['/regserver']
          end
          private :reg_server

          def unreg_server
            run_as_enterprise ['/unregserver']
          end
          private :unreg_server

          def run_as_enterprise(args)
            binary_wrapper.command(:enterprise, args)
            .run.wait.result.verify!
          end
          private :run_as_enterprise
        end

        class ThinApplication < ThickApplication
          BINARY = '1cv8c.exe'
          def binary
            BINARY
          end

          def prog_id
            "v#{v8x}c.Application"
          end

          def get_binary_wrapper
            Enterprise.thin_clients(requirement.to_s).last
          end
          private :get_binary_wrapper

          def run_as_enterprise(args)
            binary_wrapper.command(args)
            .run.wait.result.verify!
            true
          end
          private :run_as_enterprise
        end
      end
    end
  end
end
