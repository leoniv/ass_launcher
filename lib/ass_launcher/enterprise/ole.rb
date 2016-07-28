# encoding: utf-8

require 'ass_launcher/enterprise/ole/ole_binaries'

module AssLauncher
  module Enterprise
    # 1C:Enterprise ole objects layer
    module Ole
      # 1C Infobase External Connection
      class IbConnection
        attr_reader :__ole__
        protected :__ole__

        # (see OleBinaries::AbstractAssOleBinary#initialize)
        def initialize(requirement)
          @requirement = requirement.to_s
        end

        # Open connection in to infobase described in conn_str
        # @param conn_str [Support::ConnectionString::Server,
        #  Support::ConnectionString::File, String]
        def __open__(conn_str)
          return true if __opened__?
          __init_ole__(__ole_binary__.ole.connect(__cs__(conn_str)))
          true
        end

        def __init_ole__(ole)
          @__ole__ = ole
        end
        private :__init_ole__

        # Try close connection.
        # @note *It* *not* *guaranteed* *real* *closing* *connection!*
        #  Connection keep alive while have any alive WIN32OLE refs
        #  generated this connection. {WIN32OLE#\_\_ass_ole_free\_\_} try kill
        #  refs but it work not always
        # @see WIN32OLE
        def __close__
          return if __closed__?
          @__ole__.send :__ass_ole_free__
          @__ole__ = nil
        end

        # True if connection closed
        def __closed__?
          __ole__.nil?
        end

        # True if connection opened
        def __opened__?
          !__closed__?
        end

        # Set 1C Ole server properties
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
        protected :__ole_binary__

        # Try call ole method
        # @raise [RuntimeError] if object closed
        def method_missing(method, *args)
          fail "Attempt call method for closed object #{self.class.name}"\
            if __closed__?
          o = __ole__.send(method, *args)
          o
        end
        protected :method_missing
      end

      # IWorkingProcessConnection
      class WpConnection < IbConnection
        # Connection with 1C Server working process described in uri
        # @param uri [URI, String]
        def __open__(uri)
          return true if __opened__?
          __init_ole__(__ole_binary__.connectworkingprocess(uri.to_s))
          true
        end
      end

      # Wrapper for IServerAgentConnection
      class AgentConnection < IbConnection
        # Connection with 1C Server agent described in uri
        # @param (see WpConnection#__open__)
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
          @objects ||= []
        end

        # Close all opened connectons
        def self.close_all
          objects.each(&:__close__)
        end

        def initialize(requirement)
          super
          @opened = false
        end

        # (see IbConnection#__open__)
        # @raise [ApplicationConnectError]
        def __open__(conn_str)
          return true if __opened__?
          __try_open__(conn_str)
          self.class.objects << self
          __opened__?
        end

        def __try_open__(conn_str)
          @opened = __ole_binary__.ole.connect(__cs__(conn_str))
          fail ApplicationConnectError unless __opened__?
        rescue StandardError => e
          @opened = false
          @__ole_binary__ = nil
          raise e
        end
        protected :__try_open__

        def __ole__
          __ole_binary__.ole
        end
        protected :__ole__

        def __opened__?
          @opened
        end

        def __closed__?
          !__opened__?
        end

        def __close__
          return true if __closed__?
          # rubocop:disable HandleExceptions
          begin
            __ole__.terminate
          rescue
            # NOP
          ensure
            @__ole_binary__ = nil
            @opened = false
            ThinApplication.objects.delete(self)
          end
          # rubocop:enable HandleExceptions
          true
        end

        def __ole_binary__
          @__ole_binary__ ||= OleBinaries::ThinApplication.new(@requirement)
        end
        protected :__ole_binary__
      end

      # Wrapper for V8x.Application ole object
      class ThickApplication < ThinApplication
        def __ole_binary__
          @__ole_binary__ ||= OleBinaries::ThickApplication.new(@requirement)
        end
        protected :__ole_binary__
      end
    end
  end
end
