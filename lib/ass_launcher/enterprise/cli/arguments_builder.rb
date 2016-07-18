# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      # @api private
      class ArgumentsBuilder
        attr_reader :run_mode, :defined_parameters, :builded_args

        # @param defined_arguments [Parameters::ParamtersList]
        def initialize(defined_arguments, run_mode)
          @builded_args = []
          @defined_parameters = defined_arguments
          @run_mode = run_mode
        end

        def connection_string(conn_str)
          conn_str = AssLauncher::Support::ConnectionString.\
            new(conn_str) if conn_str.is_a? String
          args = conn_str_to_args(conn_str)
          args += build_args
        end

        def conn_str_to_args(conn_str)
          return conn_str.createinfobase_args if run_mode == :createinfobase
          conn_str.to_args
        end

        def method_missing(method, *args, &block)
          param_name = method_to_param_name(method)
          FIXME
        end

        def method_to_param_name(method)
          FIXME
        end

      end
    end
  end
end
