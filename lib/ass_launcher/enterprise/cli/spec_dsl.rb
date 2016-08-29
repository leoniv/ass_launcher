# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      # DSL for describe 1C:Enterprise command-line interface
      # @api public
      module SpecDsl
        require 'ass_launcher/enterprise/cli/spec_dsl/dsl_helpers'
        require 'uri'
        include DslHelpers

        # Define 1C:Enterprise version for defined CLI specifications
        # @param v [String] 1C:Enterprise verion string
        def enterprise_version(v)
          reset_all
          add_enterprise_versions Gem::Version.new(v)
        end

        # Describe run modes specifications
        # @param mode [Symbol] 1C:Enterprise run mode.
        # @param desc [String] description for run mode
        # @param banner [String] bunner for usage
        def describe_mode(mode, desc, banner)
          fail "Undefined mode: #{mode}" unless defined_modes.include? mode
          described_modes[mode] = { desc: _t(desc), banner: _t(banner) }
        end

        # Define CLI parameters group
        # @param name [Symbol] group name
        # @param desc [String] description for group
        # @param priority [Fixnum] priority for parameters group for build
        #  help message
        def define_group(name, desc, priority)
          parameters_groups[name.to_sym] =
            { desc: _t(desc), priority: priority }
        end


        # Return 1C client identifier see {BinaryMatcher::ALL_CLIENTS}
        # @return [Symbol] :thick
        def thick
          :thick
        end

        # Return 1C client identifier see {BinaryMatcher::ALL_CLIENTS}
        # @return [Symbol] :thin
        def thin
          :thin
        end

        # Return 1C client identifier see {BinaryMatcher::ALL_CLIENTS}
        # @return [Symbol] :web
        def web
          :web
        end

        # Block to define CLI parameters for run modes
        # @param modes [Array<Symbol>] run modes wich CLI parameters defined
        # @raise if passed invalid 1C:Enterprise run mode
        # @raise if call without block
        def mode(*modes, &block)
          fail_if_wrong_modes modes
          fail 'Block required' unless block_given?
          self.current_modes = modes
          instance_eval(&block)
          reset_modes
        end

        def fail_if_wrong_modes(modes)
          fail "Undefined modes #{modes}" if (defined_modes & modes).size == 0
        end
        private :fail_if_wrong_modes

        # Block to grouping CLI parameters into parameters group.
        # Group must be defined as {#define_group}
        # @param key [Symbol] group name
        # @raise if passed undefined group
        # @raise if call without block
        def group(key, &block)
          fail_if_wrong_group(key)
          fail 'Block required' unless block_given?
          self.current_group = key
          instance_eval(&block)
          reset_group
        end

        def fail_if_wrong_group(key)
          fail "Undefined parameters group #{key}" unless parameters_groups
            .key? key
        end
        private :fail_if_wrong_group

        # Build switch or chose list for CLI parameters clases:
        # {Cli::Parameters::Switch} or {Cli::Parameters::Chose}
        # @param options [Hash] +:key+ is argument for CLI parameter, +value+ is
        #  description for help message
        def switch_list(**options)
          options.each_key do |k|
            options[k] = _t(options[k])
          end
        end
        alias_method :chose_list, :switch_list

        # Define {Cli::Parameters::Path} parameter and him subparameters.
        # Subparameters defines in the block.
        # @param name [String] name of 1C:Enterprise CLI parameter
        # @param desc [String] description of 1C:Enterprise CLI parameter for
        #   build help message
        # @param clients [Array] uses DSL:
        #  {#thick}, {#thin} or {#web}. On default uses
        #  array for all 1C clients {BinaryMatcher::ALL_CLIENTS}
        # @param options (see Cli::Parameters::StringParam#initialize)
        # @return [Cli::Parameters::Path]
        def path(name, desc, *clients, **options, &block)
          new_param(Parameters::Path, name, desc,
                    clients, **options, &block)
        end

        # Path with exist validation.
        # @see #path
        # @param (see #path)
        # @return (see #path)
        def path_exist(name, desc, *clients, **options, &block)
          path(name, desc, *clients, options.merge(must_be: :exist),
               &block)
        end

        # Path with not exist validation.
        # @see #path
        # @param (see #path)
        # @return (see #path)
        def path_not_exist(name, desc, *clients, **options, &block)
          path(name, desc, *clients,
               options.merge(must_be: :not_exist),
               &block)
        end

        # Define {Cli::Parameters::StringParam} parameter and him subparameters.
        # Subparameters defines in the block.
        # @param (see #path)
        # @return [Cli::Parameters::StringParam]
        def string(name, desc, *clients, **options, &block)
          new_param(Parameters::StringParam, name, desc,
                    clients, **options, &block)
        end

        # Define {Cli::Parameters::Flag} parameter and him subparameters.
        # Subparameters defines in the block.
        # @param (see #path)
        # @return [Cli::Parameters::Flag]
        def flag(name, desc, *clients, **options, &block)
          new_param(Parameters::Flag, name, desc,
                    clients, **options, &block)
        end

        # Define {Cli::Parameters::Switch} parameter and him subparameters.
        # Subparameters defines in the block.
        # @note use helper {#switch_list} for build +:switch_list+ option
        # @param (see #path)
        # @return [Cli::Parameters::Switch]
        def switch(name, desc, *clients, **options, &block)
          new_param(Parameters::Switch, name, desc,
                    clients, options, &block)
        end

        # Define {Cli::Parameters::Chose} parameter and him subparameters.
        # Subparameters defines in the block.
        # @note use helper {#chose_list} for build +:chose_list+ option
        # @param (see #path)
        # @return [Cli::Parameters::Chose]
        def chose(name, desc, *clients, **options, &block)
          new_param(Parameters::Chose, name, desc,
                    clients, options, &block)
        end

        # Define {Cli::Parameters::StringParam} parameter suitable for
        # validation URL argument. Subparameters defines in the block.
        # @note It initialize +:value_validator+ option with +Proc+
        # @param (see #path)
        # @return [Cli::Parameters::StringParam]
        def url(name, desc, *clients, **options, &block)
          options[:value_validator] = url_value_validator(name)
          string(name, desc, clients, options, &block)
        end

        def url_value_validator(n)
          proc do |value|
            begin
              URI(value)
            rescue
              raise ArgumentError,
                    "Invalid URL for parameter `#{n}': `#{value}'"
            end
            value
          end
        end
        private :url_value_validator

        # Define {Cli::Parameters::StringParam} parameter suitable for
        # validation numeric argument. Subparameters defines in the block.
        # @note It initialize +:value_validator+ option with +Proc+
        # @param (see #path)
        # @return [Cli::Parameters::StringParam]
        def num(name, desc, *clients, **options, &block)
          options[:value_validator] = num_value_validator(name)
          string(name, desc, clients, options, &block)
        end

        def num_value_validator(n)
          proc do |value|
            begin
              Float(value)
            rescue
              raise ArgumentError,
                    "Invalid Number for parameter `#{n}': `#{value}'"
            end
            value
          end
        end
        private :num_value_validator

        # Restrict already specified parameter +name+
        # recursively with all subparameters
        # @param name (see #path)
        # @return (see DslHelpers#restrict_params)
        def restrict(name)
          restrict_params(name, current_version)
        end

        # Change specifications of subparameters for already
        # specified parameter +name+
        def change(name, &block)
          change_param name, &block
        end

        # Stub for skipped parameter. Many 1C:Enterprise CLI parameters is not
        # imprtant for describe in {Cli::CliSpec}. For define it fact, you can
        # use this method.
        # @todo may be registring skipped parameter for worning?
        # @param (see #path)
        # @return [nil]
        def skip(name, desc = '', *clients, **options, &block)
          # nop
        end
      end # SpecDsl
    end
  end
end
