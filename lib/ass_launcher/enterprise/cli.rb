# encoding: utf-8

module AssLauncher
  class Configuration
    # 1C Enterprise cli specifications text written on Cli::SpecDsl
    def platform_cli_spec
      @platform_cli_spec ||= Enterprise::Cli::CliSpec.load
    end
  end
  module Enterprise
    # @api private
    # 1C:Enterprise cli api wrapper
    module Cli
      require 'ass_launcher/enterprise/cli/arguments_builder'
      require 'ass_launcher/enterprise/cli/parameters'
      require 'ass_launcher/enterprise/cli/spec_dsl'

      # Run modes defined for 1C Enterprise clients
      DEFINED_MODES = [
        :createinfobase,
        :enterprise,
        :designer,
        :webclient
      ].freeze

      # Return suitable run_mode see {DEFINED_MODES} for
      # 1c client
      # @param cl [BinaryWrapper::ThinClient, BinaryWrapper::ThickClient]
      # @return [Array<Symbol>]
      def self.defined_modes_for(cl)
        return [DEFINED_MODES[1]] if cl.instance_of? BinaryWrapper::ThinClient
        return DEFINED_MODES if cl.instance_of? BinaryWrapper::ThickClient
      end

      # Load and 1C Enterprise cli specifications
      # for buld cli api and cli api help
      class CliSpec
        def self.loader(binary, run_mode)
          Class.new do
            include AssLauncher::Enterprise::Cli::SpecDsl
            attr_reader :run_mode, :binary_wrapper
            def initialize(binary_wrapper, run_mode)
              @binary_wrapper = binary_wrapper
              @run_mode = run_mode
            end
          end.new(binary, run_mode)
        end
        private_class_method :loader

        # @api private
        # @todo In future, may be, should extract +cli.spec+ and use
        #  configurable +cli.spec+ path
        def self.load
          spec = File.read(File.expand_path('../cli/cli.spec',__FILE__))
        end

        # Max 1C Enterprise version
        # for which defined parameters
        # @return [Gem::Version]
        attr_reader :enterprise_version
        # Defined 1C Enterprise cli parameters
        # @return [Parameters::ParamtersList]
        attr_reader :parameters
        # 1C Enterprise run modes descriptions for build cli api help
        # @return (see Cli::SpecDsl#described_modes)
        attr_reader :run_modes
        # Description for 1C Enterprise cli parameters group for group
        #  parameters in cli help
        # @return (see Cli::SpecDsl#described_modes)
        attr_reader :groups

        attr_reader :current_run_mode

        attr_reader :current_binary_wrapper

        # @api private
        def initialize(parameters, modes, groups,
                       enterprise_version, binary_wrapper, run_mode)
          @run_modes = modes.select { |k, v| binary_wrapper.run_modes.include? k }
          @groups = groups
          @enterprise_version = enterprise_version
          @current_run_mode = run_mode
          @current_binary_wrapper = binary_wrapper
          @parameters = parameters
        end

        # Build suitable cli specifications for 1C Enterprise binary type,
        # version and run mode
        # @param binary [BinaryWrapper::ThinClient, BinaryWrapper::ThickClient]
        # @param run_mode [Symbol] see {Cli::DEFINED_MODES}
        def self.for(binary, run_mode)
          l = loader(binary, run_mode)
          l.instance_eval(AssLauncher.config.platform_cli_spec)
          new(l.parameters,
              l.described_modes,
              l.parameters_groups,
              l.enterprise_version,
              binary,
              run_mode)
        end

        # :nocov:
        # @todo Implemets this
        def usage(run_mode = nil)
          raise NotImplementedError
        end
        # :nocov:
      end

      # @api private
      class BinaryMatcher
        attr_reader :client, :requirement
        def initialize(client = :all, version = '>= 0')
          @client = client.to_sym
          @requirement = Gem::Requirement.new version
        end

        def match?(binary_wrapper)
          match_client?(binary_wrapper) && match_version?(binary_wrapper)
        end

        private
        def match_client?(bw)
          return true if client == :all
          client == bw.class.name.split('::').last.
            to_s.downcase.gsub(/client$/,'').to_sym
        end

        def match_version?(bw)
          requirement.satisfied_by? bw.version
        end
      end
    end
  end
end
