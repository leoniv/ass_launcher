# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      class DefinedParameters
        module Dsl
          def thick_client(v = '>= 0')
            BinaryMatcher.new(:thick, v)
          end

          def thin_client(v = '>= 0')
            BinaryMatcher.new(:thin, v)
          end

          def all_client(v = '>= 0')
            BinaryMatcher.new(:all, v)
          end

          def parameters
            @parameters ||= ParamtersList.new
          end

          def define(parameter, &block)
            parameters.define(parameter, &block)
          end
          private :define

          def describe(scope, &block)
            scope.instance_eval block
          end
          private :describe

          def mode(modes, &block)
            raise 'FIXME'
          end
        end # Dsl
        extend Dsl
        def self.build_api(object, binary_wrapper, run_mode)
          raise 'FIXME'
          object.instance_variable_set(:@defined_parameters, new(binary_wrapper, run_mode))
        end

        def initialize(binary_wrapper, run_mode)
          @mode
        end

        # @api private
        class BinaryMatcher
          def initialize(client = :all, version = '>= 0')
            @client = client.to_sym
            @requirement = Gem::Requirement.new version
          end

          def match?(binary_wrapper)
            match_client(binary_wrapper) && match_version(binary_wrapper)
          end

          private
          def match_client(bw)
            return true if @client == :all
            @client == bw.class.name.to_s.downcase.gsub(/client$/,'').to_sym
          end

          def match_version(bw)
            @requirement.satisfied_by? bw.version
          end
        end

        class Parameter
          attr_reader :name
          attr_reader :desc
          attr_reader :binary_matcher
          attr_reader :config
          attr_reader :block
          attr_reader :parameters

          def initialize(name, desc, binary_matcher = nil, **config)
            @name = name
            @desc = desc
            @binary_matcher = binary_matcher || BinaryMatcher.new
          end

          def match?(binary_wrapper)
            binary_mather.match? binary_wrapper
          end

          def to_sym
            raise 'FIXME'
          end
        end

        class ParamtersList
          attr_reader :hash
          private :hash
          def initialize()
            @parameters = []
          end

          def defined?(parameter)
            to_hash.key?(parameter.to_sym)
          end

          def to_hash
            res = {}
            parameters.each do |p|
              res[p.to_sym] = p
            end
            res
          end
        end
      end # DefinedParameters

      class ArgumetsBuilder
        attr_reader :connection_string, :defined_parameters, :binary_wrapper,
          :run_mode, :args

        def initialize(binary_wrapper, run_mode)
          @binary_wrapper = binary_wrapper
          @run_mode = run_mode
          @args = []
          build_api
        end

        def build_api
          DefinedParameters.build_api(self, binary_wrapper, run_mode)
        end

        def connection_string(conn_str)
          @connection_string = AssLauncher::Support::ConnectionString.\
            new(conn_str) if conn_str.is_a? String
          verify_connection_string!
          case run_mode
          when  :createinfobase
            args.unshift connection_string.to_s(
              AssLauncher::Support::ConnectionString::FILE_FIELDS +
              AssLauncher::Support::ConnectionString::SERVER_FIELDS +
              AssLauncher::Support::ConnectionString::IB_MAKER_FIELDS
            )
          else
            instance_eval connection_string.to_args
          end
        end

        def verify_connection_string?
          fail "Wrong connection_string: #{connection_string.is}"\
            " for mode: #{run_mode}" if binary_wrapper.accepted_connstr.\
            include?(run_mode)
        end
        private :verify_connection_string?

        def to_array
          args.dup
        end
      end
    end
  end
end
