# encoding: utf-8

module AssLauncher
  module Enterprise
    module WebClients
      require 'uri'
      # Return object for run 1C webclent in required internet browser
      # @param engine [Symbol] - engine required for run 1C webclent
      # @return [WebClient]
      # @example
      #  wc = AssLauncher::Enterprise::WebClient.new(:firefox) do
      #    connection_string = 'ws="http://host:port/infobase";'
      #    #or without connection_string
      #    uri = "http://user:password@host:port/path/to/infobase'
      #    _O :low
      #    _C 'passed string'
      #    _N = '1cuser'
      #    _P = '1cuser_password'
      #    _WA :'-'
      #    _OIDA :'-'
      #    Authoff
      #    _L 'en'
      #    _WL
      #    _TESTCLIENTID 'id'
      #    _DebuggerURL 'localhost'
      #    _UsePrivilegedMode
      #  end
      def self.new(engine, &block)
        fail ArgumentError, "Invalid engine `#{engine}'"\
          unless ENGINES.include? engine
            cl = WebClient.new(ENGINES[engine].new)
          cl.command(&block) if block_given?
          cl
      end

      # @abstract
      class WebClient
        # TODO: Doc this
        module Dsl
          def connection_string(cs)
            uri validate_connection_string(cs).uri
          end

          def validate_connection_string(cs)
            conn_str = AssLauncher::Support::ConnectionString\
              .new(cs.to_s)
            fail ArgumentError unless conn_str.is?(VALID_CONNECTION_STRING)
            conn_str
          end
          private :validate_connection_string

          def uri(s)
            @uri = URI(s.to_s)
          end
        end

        include Dsl
        VALID_CONNECTION_STRING = :http

        def initialize(engine)
          connection_string AssLauncher::Support::ConnectionString\
            .new('ws="http://example.com"')
          @engine = engine
          yield self if block_given?
        end

        def command(args = [], &block)
          @args = args + ['DisableStartupMessages','']
          @args += build_arags(&block)
        end

        def cli_spec
          AssLauncher::Enterprise::Cli::CliSpec.for(self, :webclient)
        end

        def version
          Gem::Version.new('8.2')
        end

        def run_modes
          [:webclient]
        end

        def build_args
          # TODO: build args like BinaryWrapper base on cli_spec
          fail NotImplementedError
        end
        private :build_args

        def args
          @args ||= []
        end
        private :args

        def uri_get
          @uri
        end
        private :uri_get

        def url
          r = uri_get
          q = args_to_query
          r.query += "&#{q}" if q
          r.to_s
        end

        def args_to_query
          r = ''
          args.each_with_index do |v, i|
            next if i.even?
            r << "#{v}"
            r << "=#{args[i+1]}" if args[i+1]
            r << "&"
          end
          r.gsub!(/&$/,'')
          return nil if r.empty?
          r
        end
        private :args_to_query

        # @todo TODO: можно запускать как драйвер силениум
        def run(args)
          raise NotImplementedError
        end
      end # Client
      class Firefox; end
      class IE; end
      class Chrome; end
      class Safary; end

      ENGINES = { firefox: Firefox,
                   iexplore: IE,
                   chrome: Chrome,
                   safary: Safary
      }.freeze
    end
  end
end
