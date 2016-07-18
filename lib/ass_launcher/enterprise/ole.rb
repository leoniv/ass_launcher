# encoding: utf-8

#Monkey patch for WIN32OLE class
#-Define dummy class for Linux
#-Modification bihavior for ole_free method. FIXME: 1с соединение с ИБ остается
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
    # FIXME: IT NOT WORK. IT FAIL
    def self.__ass_ole_free__(obj)
     return if WIN32OLE.ole_reference_count(obj) <= 0
     WIN32OLE.ole_reference_count(obj).times.each do |i|
        WIN32OLE.ole_free obj
     end
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
        attr_reader :__ole__, :__version__
        def initialize(v)
          @__version__ = Gem::Version.new(v.to_s)
          __main_ole__ #It cal for faile if linux
        end

        def __open__(conn_str)
          return if __opened__?
          @__ole__ = __main_ole__.connect(conn_str.to_s)
        end

        def __main_ole__
          @__main_ole__ ||= Ole.com_connector(__version__).ole
        end
        protected :__main_ole__

        def __closed__?
          __ole__.nil?
        end

        def __opened__?
          !__closed__?
        end

        def __close__
          return if __closed__?
          #__main_ole__.ole_free
          __main_ole__.send :__ass_ole_free__
          @__main_ole__ = nil
          @__ole__ = nil
        end

        def __configure_com_connector__(**opts)
          opts.each do |k, v|
            __main_ole__.setproperty(k, v)
          end
        end

        def method_missing(method, *args)
          fail 'FIXME' if __closed__?
          begin
            __ole__.send(method, *args);
          rescue Exception => e
            #FIXME: gets current win encoding???
            fail e.class, e.meassage.encode!('utf-8', 'cp1251')
          end
        end
      end

      # IWorkingProcessConnection
      class WpConnection < IbConnection
        def __open__(uri)
          return if __opened__?
          @__ole__ = __main_ole__.connectworkingprocess(uri.to_s)
        end
      end

      # IServerAgentConnection
      class AgentConnection < IbConnection
        def __open__(uri)
          return if __opened__?
          @__ole__ = __main_ole__.connectagent(uri.to_s)
        end
      end

      class ApplicationConnectError < StandardError; end

      class ThinApplication < IbConnection
        def __open__(conn_str)
          fail ApplicationConnectError unless\
            __main_ole__.connect(conn_str.to_s)
          @__ole__ = __main_ole__
        end

        def __main_ole__
          @__main_ole__ ||= Ole.thin_application(__version__).ole
        end
        protected :__main_ole__
      end

      class ThickApplication < ThinApplication
        def __main_ole__
          @__main_ole__ ||= Ole.thick_application(__version__).ole
        end
        protected :__main_ole__
      end

      module OleBinaries
        # @abstract
        class AbstractAssOleBinary
          include AssLauncher::Support::Platforms
          attr_reader :version
          def initialize(v)
            @version = Gem::Version.new(v)
          end

          def ole
            @ole ||= new_ole
          end

          def new_ole
            #FIXME: fail if version not instaled or not registred
            WIN32OLE.new(prog_id)
          end

          def v8x(v)
            v.to_s.split('.').slice(0,2).join('')
          end
          private :v8x

          def instaled?
            #FIXME
          end

          def registred?
            #FIXME
          end

          def regsvr
            #FIXME
          end
        end
        class COMConnector < AbstractAssOleBinary
          BINARY = 'comsntr.dll'
          def binary
            BINARY
          end

          def prog_id
            "v#{v8x(version.to_s)}.COMConnector"
          end
        end

        class ThickApplication < AbstractAssOleBinary
          BINARY = '1cv8.exe'
          def binary
            BINARY
          end

          def prog_id
            "v#{v8x(version.to_s)}.Application"
          end
        end

        class ThinApplication < AbstractAssOleBinary
          BINARY = '1cv8c.exe'
          def binary
            BINARY
          end

          def prog_id
            "v#{v8x(version.to_s)}c.Application"
          end
        end
      end

      # IV8COMConnector
      def self.com_connector(v)
        r = OleBinaries::COMConnector.new(v)
      end

      def self.thick_application(v)
        r = OleBinaries::ThickApplication.new(v)
      end

      def self.thin_application(v)
        r = OleBinaries::ThinApplication.new(v)
      end
    end
  end
end
