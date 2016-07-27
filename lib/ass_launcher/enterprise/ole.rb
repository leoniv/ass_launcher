# encoding: utf-8

require 'ass_launcher/enterprise/ole/ole_binaries'

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

        # FIXME: внешнее соединение
        # с ИБ остается [AssLauncher::Enterprise::Ole::IBConnection]
        # активным пока существует хотябы один объект порожденный этим соединением.
        # Объекты могут пораждать другие объекты и т.д. Ссылки на объекты могут
        # находиться как на строне Ruby так и на строне 1С. Теоретически если на стороне
        # Ruby держать все ссылки на объекты и вызвать для них ole_free соеденинение
        # должно закрыться. Но 1С объекты могут ссылаться на другие объекты тогда
        # ole_free для бъекта на которого есть ссылки на строне 1С не сработает.
        # @note It work not correct. It is not guaranteed to close connection.
        #  FIXME: translate: соединение с ИБ останется активным
        #  если будет существовать хотябы одна ссылка на ole объект порожденный
        #  соединение. Вызов {#__ass_ole_free__} попытается вызват {#ole_free}
        #  для всех ссылок но это работает не всегда.
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
    end
  end
end
