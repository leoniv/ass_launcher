# encoding: utf-8

module AssLauncher
  module Enterprise
    # @api private
    # 1C:Enterprise cli api wrapper
    module Cli
      require 'ass_launcher/enterprise/cli/arguments_builder'
      require 'ass_launcher/enterprise/cli/parameters'
      require 'ass_launcher/enterprise/cli/spec_dsl'
      require 'ass_launcher/enterprise/cli/binary_matcher'

      # Run modes defined for 1C Enterprise clients
      DEFINED_MODES = [
        :createinfobase,
        :enterprise,
        :designer,
        :webclient
      ].freeze

      # Return suitable run_mode see {DEFINED_MODES} for
      # 1c client
      # @param klass [BinaryWrapper::ThinClient, BinaryWrapper::ThickClient,
      #  WebClient]
      # @return [Array<Symbol>]
      def self.defined_modes_for(klass)
        return [DEFINED_MODES[1]] if klass == BinaryWrapper::ThinClient
        return DEFINED_MODES - [:webclient]\
          if klass == BinaryWrapper::ThickClient
        return [DEFINED_MODES.last] if klass == WebClient
      end

      # 1C Enterprise cli specifications
      # for {BinaryWrapper::ThinClient}, {BinaryWrapper::ThickClient}
      # or for {WebClient} and specified +run_mode+
      # TODO: refactoring delete run_mode
      # @api public
      class CliSpec

        # TODO: refactoring delete run_mode
        attr_reader :run_mode
        alias_method :current_run_mode, :run_mode

        # see +binary_wrapper+ parameter for {#initialize}
        attr_reader :binary_wrapper
        alias_method :current_binary_wrapper, :binary_wrapper

        # @param (see Cli::Parameters::AllParameters#to_parameters_list)
        # TODO: refactoring initialize(binary_wrapper)
        def initialize(binary_wrapper, run_mode)
          @run_mode = run_mode
          @binary_wrapper = binary_wrapper
        end

        # Return parameters specified for
        # 1C:Enterprise client wrappend into {#binary_wrapper}
        # @return [Cli::Parameters::ParametersList]
        def parameters
          # TODO: refactoring parameters(run_mode)
          # TODO: validate run_mode
          cli_def.parameters.to_parameters_list(binary_wrapper, run_mode)
        end

        # @return [CliDef]
        def self.cli_def
          @cli_def ||= load_cli_def
        end

        # (see .cli_def)
        def cli_def
          self.class.cli_def
        end

        def self.load_cli_def
          require 'ass_launcher/enterprise/cli_def'
          CliDef
        end
        private_class_method :load_cli_def

        # Build suitable cli specifications for 1C Enterprise binary type,
        # version and run mode
        # @param (see #initialize)
        def self.for(binary_wrapper, run_mode)
          new(binary_wrapper, run_mode)
        end

        # :nocov:
        # @todo Implemets this
        def usage(run_mode = nil)
          raise NotImplementedError
        end
        # :nocov:
      end
    end
  end
end
