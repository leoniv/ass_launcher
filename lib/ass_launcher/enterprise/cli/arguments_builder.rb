# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      # @api private
      class ArgumentsBuilder
        class BuildError < StandardError; end
        METHOD_TO_PARAM_NAME = /^_/i
        TOP_LEVEL_PARAM_KEY = '/'
        NESTED_LEVEL_PARAM_KEY = '-'

        # Heler for top lever parameter builder
        module InspectConnectionString
          def connection_string(conn_str)
            conn_str = AssLauncher::Support::ConnectionString\
                       .new(conn_str) if conn_str.is_a? String
            args = conn_str_to_args(conn_str)
            self.builded_args = args + builded_args
          end

          def conn_str_to_args(conn_str)
            return conn_str.createinfobase_args if run_mode == :createinfobase
            conn_str.to_args
          end
          private :conn_str_to_args
        end

        def self.build_args(binary_wrapper, run_mode, &block)
          new(binary_wrapper.cli_spec(run_mode)).build_args(&block)
        end

        attr_reader :cli_spec, :params_stack, :parent_parameter
        attr_accessor :builded_args

        # @param cli_spec [CliSpec]
        # @param parent_parameter [Cli::Parameters] parent for nested params
        def initialize(cli_spec, parent_parameter = nil)
          @builded_args = []
          @cli_spec = cli_spec
          @parent_parameter = parent_parameter
          @params_stack = []
        end

        def run_mode
          cli_spec.current_run_mode
        end

        def defined_parameters
          cli_spec.parameters
        end

        def binary_wrapper
          cli_spec.current_binary_wrapper
        end

        # Evaluate &block return array of arguments
        # @raise [ArgumentError] unless block given
        def build_args(&block)
          fail ArgumentError, 'Block require' unless block_given?
          extend InspectConnectionString unless parent_parameter
          instance_eval(&block)
          builded_args
        end

        def nested_builder(parent_parameter)
          self.class.new(cli_spec, parent_parameter)
        end
        private :nested_builder

        def method_missing(method, *args, &block)
          param = param_find(method)
          fail_no_parameter_error(method) unless param
          fail_if_parameter_exist(param)
          add_args(param.to_args param_argument_get(param, args))
          self.builded_args += nested_builder(param).build_args(&block)\
            if block_given?
        end

        def fail_if_parameter_exist(param)
          fail(BuildError, "Parameter `#{param.full_name}' alrady build.")\
            if params_stack.include? param
          params_stack << param
        end
        private :fail_if_parameter_exist

        def param_argument_get(param, args)
          v = args[0]
          fail ArgumentError, "Parameter #{param.full_name} require argument"\
            if param.argument_require && v.nil?
          v
        end
        private :param_argument_get

        def add_args(args)
          self.builded_args = builded_args + args
        end
        private :add_args

        def fail_no_parameter_error(method)
          fail BuildError,
               "CLI parameter `#{to_param_name(method)}' not definded"\
               " for `#{bw_pesentation}' in `#{run_mode}' run mode."\
        end
        private :fail_no_parameter_error

        def bw_pesentation
          "#{binary_wrapper.class.name.split('::').last}"\
          " #{binary_wrapper.version}"
        end
        private :bw_pesentation

        def param_find(method)
          defined_parameters.find(to_param_name(method), parent_parameter)
        end
        private :param_find

        def to_param_name(method)
          param_key + method.to_s.gsub(METHOD_TO_PARAM_NAME, '')
        end
        private :to_param_name

        def param_key
          return TOP_LEVEL_PARAM_KEY unless parent_parameter
          NESTED_LEVEL_PARAM_KEY
        end
        private :param_key
      end
    end
  end
end
