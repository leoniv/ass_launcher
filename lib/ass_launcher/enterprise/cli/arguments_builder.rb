# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      # @api private
      # Provides DSL for build arguments for run 1C:Enterprise clients.
      #
      # DSL dynamically generated based on CLI specifications {Cli::CliSpec}
      # For each CLI parameter is assigned a DSL method called
      # like a parameter but whitout parameter key such as
      # {TOP_LEVEL_PARAM_KEY} or {NESTED_LEVEL_PARAM_KEY}.
      # DSL methods may be prefixed +_+ char for
      # escape uppercase name of method. DSL method +_SomeParameter+ and
      # +someParameter+ equal and assigned for +/SomParameter+ or
      # +-SomeParameter+ CLI parameter. DLS methods case insensitive.
      # Top level builder have method
      # {IncludeConnectionString#connection_string} for pass connection
      # string and convert connection string into arguments array.
      # @example
      #  client = AssLauncher::Enterprise.thick_clients('> 0').sort.last
      #  # Builds arguments for check configuration:
      #
      #  # 1) Use #connection_string DLS method
      #  args = AssLauncher::Enterprise::Cli::ArgumentsBuilder.build_args(
      #           client, :designer) do
      #    connection_string 'File="tmp/new.ib";Usr="user";Pwd="password";'
      #    checkConfig do            # top level CLI parameter '/CheckConfig'
      #       unreferenceProcedures  # nested parameter '-UnreferenceProcedures'
      #     end
      #  end
      #  args #=> ["/N", "user",\
      #  # "/P", "password",
      #  # "/F", "C:/cygwin/home/vlv/workspace/ass_launcher/tmp/new.ib",
      #  # "/CheckConfig", "", "-UnreferenceProcedures", ""]
      #
      #  # 2) Without #connection_string DLS method
      #  args = AssLauncher::Enterprise::Cli::ArgumentsBuilder.build_args(
      #            client, :designer) do
      #    _N 'user'
      #    _P 'password'
      #    _F 'tmp/new.ib'
      #    _CheckConfig do
      #      _UnreferenceProcedures
      #    end
      #  end
      #  args #=> ["/N", "user",
      #  # "/P", "password",
      #  # "/F", "C:/cygwin/home/vlv/workspace/ass_launcher/tmp/new.ib",
      #  # "/CheckConfig", "", "-UnreferenceProcedures", ""]
      #
      # @raise (see #method_missing )
      class ArgumentsBuilder
        class BuildError < StandardError; end
        METHOD_TO_PARAM_NAME = /^_/i
        TOP_LEVEL_PARAM_KEY = '/'
        NESTED_LEVEL_PARAM_KEY = '-'

        # DSL method {#connection_string} for top level arguments builder
        # @api public
        module IncludeConnectionString
          # DLS method for convert connection string into 1C:Enterprise cli
          # arguments and add them on the head of arguments array.
          #
          # @param conn_str [String
          #  AssLauncher::Support::ConnectionString::Server
          #  AssLauncher::Support::ConnectionString::File
          #  AssLauncher::Support::ConnectionString::Http] connection string
          #
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

        # @param binary_wrapper [AssLauncher::Enterprise::BinaryWrapper]
        #  subclass
        # @param run_mode [Symbol]
        # @return [Array] arguments for run 1C:Enterprise client
        def self.build_args(binary_wrapper, run_mode, &block)
          new(binary_wrapper.cli_spec, run_mode).build_args(&block)
        end

        attr_reader :cli_spec, :params_stack, :parent_parameter, :run_mode
        private :cli_spec, :params_stack, :parent_parameter, :run_mode
        attr_accessor :builded_args
        protected :builded_args, :builded_args=

        # @param cli_spec [CliSpec]
        # @param parent_parameter [Cli::Parameters] parent for nested params
        def initialize(cli_spec, run_mode, parent_parameter = nil)
          @builded_args = []
          @cli_spec = cli_spec
          @parent_parameter = parent_parameter
          @params_stack = []
          @run_mode = run_mode
        end

        def defined_parameters
          cli_spec.parameters(run_mode)
        end
        private :defined_parameters

        def binary_wrapper
          cli_spec.binary_wrapper
        end
        private :binary_wrapper

        # Evaluate &block return array of arguments
        # @raise [ArgumentError] unless block given
        def build_args(&block)
          fail ArgumentError, 'Block require' unless block_given?
          extend IncludeConnectionString\
            if (parent_parameter.nil? && run_mode != :webclient)
          instance_eval(&block)
          builded_args
        end

        def nested_builder(parent_parameter)
          self.class.new(cli_spec, run_mode, parent_parameter)
        end
        private :nested_builder

        # @raise [BuildError] if could not find parameter
        # @raise [BuildError] if argument already build
        # @raise [ArgumentError] if invlid value passed in parameter
        def method_missing(method, *args, &block)
          param = param_find(method)
          fail_no_parameter_error(method) unless param
          fail_if_parameter_exist(param)
          add_args(param.to_args(*param_argument_get(param, args)))
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
          v = args[0, param.arguments_count]
          fail_wrong_number_arguments(param.full_name, param.arguments_count,
                                      v.size) if param.argument_require
          v
        end
        private :param_argument_get

        def fail_wrong_number_arguments(name, req, act)
          fail ArgumentError, "Parameter #{name}"\
            " wrong number of arguments (#{req} for #{act})" if req != act

        end
        private :fail_wrong_number_arguments

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
