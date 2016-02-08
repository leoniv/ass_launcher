# encoding: utf-8

module AssLauncher
  module Enterprise
    module WebClients
      module DefinedArguments
        def self.extented(base)
          raise "FIXME #{base}"
        end
      end

      # Return object for run 1C webclent in required internet browser
      # @param name [Symbol] - name of required internet browser for
      #  run 1C webclent
      # @return [WebClients::IE, WebClients::Firefox, WebClients::Chrome,
      #  WebClients::Safary]
      def self.client(name)
        fail ArgumentError, "Invalid client name `#{name}'"\
          unless BROWSERS.include? name
        BROWSERS[name]
      end

      # @abstract
      class Client
        def accepted_connstr
          [:http]
        end

        def initialize(connection_string)
          @connection_string = connection_string
          validate_connection_string
          extend DefinedArguments
        end

        def validate_connection_string
          raise 'FIXME'
          #fail ArgumentError, "Invalid connection_string \
          #`#{@connection_string}'"\
          #unless accepted_connstr.include?(@connection_string.is)
        end

        # @todo TODO: можно запускать как драйвер силениум
        def run(args)
          raise 'FIXME'
        end
      end # Client
      class Firefox < Client; end
      class IE < Client; end
      class Chrome < Client; end
      class Safary < Client; end

      BROWSERS = { firefox: Firefox,
                   iexplore: IE,
                   chrome: Chrome,
                   safary: Safary
      }.freeze
    end
  end
end
