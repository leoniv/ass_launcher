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
        def enterprise_version(v = '0')
          @enterprise_version ||= Gem::Version.new(v)
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

        # Binary matcher for 1C:Enterprise thick client for which CLI parameter
        # defined
        # @param v [String] version of 1C:Enterprise client
        # @return [Cli::BinaryMatcher]
        def thick_client(v = '>= 0')
          BinaryMatcher.new(:thick, v)
        end

        # Binary matcher for 1C:Enterprise thin client for which CLI parameter
        # defined
        # @param (see #thick_client)
        # @return (see #thick_client)
        def thin_client(v = '>= 0')
          BinaryMatcher.new(:thin, v)
        end

        # Binary matcher for 1C:Enterprise thin and thick clients for
        # which CLI parameter defined
        # @param (see #thick_client)
        # @return (see #thick_client)
        def all_client(v = '>= 0')
          BinaryMatcher.new(:all, v)
        end

        # Block to define CLI parameters for run modes
        # @param modes [Array<Symbol>] run modes wich CLI parameters defined
        # @raise if passed invalid 1C:Enterprise run mode
        # @raise if call without block
        def mode(*modes, &block)
          fail "Undefined modes #{modes}" if (defined_modes & modes).size == 0
          fail 'method `mode` block required' unless block_given?
          self.current_modes = modes
          instance_eval(&block)
        end

        # Block to grouping CLI parameters into parameters group.
        # Group must be defined as {#define_group}
        # @param key [Symbol] group name
        # @raise if passed undefined group
        # @raise if call without block
        def group(key, &block)
          fail "Undefined parameters group #{key}"\
            unless parameters_groups.key? key
          fail 'method `group` block required' unless block_given?
          self.current_group = key
          instance_eval(&block)
        end

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
        # @param binary_matcher [Cli::BinaryMatcher] uses DSL:
        #  {#thick_client}, {#thin_client} or {#all_client}. If +nil+ uses
        #  {Cli::BinaryMatcher} for all 1C clients and all client's
        #  verions like returns {#all_client} method
        # @param options (see Cli::Parameters::StringParam#initialize)
        # @return [Cli::Parameters::Path]
        def path(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::Path, name, desc,
                    binary_matcher, **options, &block)
        end

        # Define {Cli::Parameters::StringParam} parameter and him subparameters.
        # Subparameters defines in the block.
        # @param (see #path)
        # @return [Cli::Parameters::StringParam]
        def string(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::StringParam, name, desc,
                    binary_matcher, **options, &block)
        end

        # Define {Cli::Parameters::Flag} parameter and him subparameters.
        # Subparameters defines in the block.
        # @param (see #path)
        # @return [Cli::Parameters::Flag]
        def flag(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::Flag, name, desc,
                    binary_matcher, **options, &block)
        end

        # Define {Cli::Parameters::Switch} parameter and him subparameters.
        # Subparameters defines in the block.
        # @note use helper {#switch_list} for build +:switch_list+ option
        # @param (see #path)
        # @return [Cli::Parameters::Switch]
        def switch(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::Switch, name, desc,
                    binary_matcher, **options, &block)
        end

        # Define {Cli::Parameters::Chose} parameter and him subparameters.
        # Subparameters defines in the block.
        # @note use helper {#chose_list} for build +:chose_list+ option
        # @param (see #path)
        # @return [Cli::Parameters::Chose]
        def chose(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::Chose, name, desc,
                    binary_matcher, **options, &block)
        end

        # Define {Cli::Parameters::StringParam} parameter suitable for
        # validation URL argument. Subparameters defines in the block.
        # @note It initialize +:value_validator+ option with +Proc+
        # @param (see #path)
        # @return [Cli::Parameters::StringParam]
        def url(name, desc, binary_matcher = nil, **options, &block)
          options[:value_validator] = url_value_validator(name)
          string(name, desc, binary_matcher, **options, &block)
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
        def num(name, desc, binary_matcher = nil, **options, &block)
          options[:value_validator] = num_value_validator(name)
          string(name, desc, binary_matcher, **options, &block)
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

        # Stub for skipped parameter. Many 1C:Enterprise CLI parameters is not
        # imprtant for describe in {Cli::CliSpec}. For define it fact, you can
        # use this method.
        # @todo may be registring skipped parameter for worning?
        # @param (see #path)
        # @return [nil]
        def skip(name, desc = '', binary_matcher = nil, **options, &block)
          # nop
        end
      end # SpecDsl
    end
  end
end
