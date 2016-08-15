# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      # @api private
      class ArgumentsBuilder

        def self.build_args(binary_wrapper, run_mode, &block)
          new(binary_wrapper.cli_spec(run_mode).parameters,
              run_mode).build_args(&block)
        end


        def build_args(&block)
          fail ArgumentError, 'Block require' unless block_given?
          raise 'FIXME'
        end

        attr_reader :run_mode, :defined_parameters, :builded_args

        # @param defined_parameters [Parameters::ParamtersList]
        # @param run_mode [Symbol]
        def initialize(defined_parameters, run_mode)
          require 'pry'
          binding.pry
          @builded_args = []
          @defined_parameters = defined_parameters
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
