# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      class ArgumentsBuilder
        attr_reader :connection_string, :defined_parameters, :builded_args

        # @param defined_arguments [Parameters::ParamtersList]
        def initialize(defined_arguments)
          @builded_args = []
          @defined_parameters = defined_arguments
          build_api
        end

        def build_api
          @defined_parameters.build_api(self)
        end

        def connection_string(conn_str)
          @connection_string = AssLauncher::Support::ConnectionString.\
            new(conn_str) if conn_str.is_a? String
          verify_connection_string!
          case run_mode
          when  :createinfobase
            builded_args.unshift connection_string.to_s(
              AssLauncher::Support::ConnectionString::FILE_FIELDS +
              AssLauncher::Support::ConnectionString::SERVER_FIELDS +
              AssLauncher::Support::ConnectionString::IB_MAKER_FIELDS
            )
          else
            raise "FIXME: where convert connection_string to args?"
            instance_eval connection_string.to_args
          end
        end

        def verify_connection_string?
          fail "Wrong connection_string: #{connection_string.is}"\
            " for mode: #{run_mode}" if binary_wrapper.accepted_connstr.\
            include?(run_mode)
        end
        private :verify_connection_string?
      end
    end
  end
end
