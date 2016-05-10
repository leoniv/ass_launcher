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

        def enterprise_version(v = '0')
          @enterprise_version ||= Gem::Version.new(v)
        end

        def describe_mode(mode, desc, banner)
          fail "Undefined mode: #{mode}" unless defined_modes.include? mode
          described_modes[mode] = { desc: _t(desc), banner: _t(banner) }
        end

        def define_group(name, desc, priority)
          parameters_groups[name.to_sym] =
            { desc: _t(desc), priority: priority }
        end

        def thick_client(v = '>= 0')
          BinaryMatcher.new(:thick, v)
        end

        def thin_client(v = '>= 0')
          BinaryMatcher.new(:thin, v)
        end

        def all_client(v = '>= 0')
          BinaryMatcher.new(:all, v)
        end

        def mode(*modes, &block)
          fail "Undefined modes #{modes}" if (defined_modes & modes).size == 0
          fail 'method `mode` block required' unless block_given?
          self.current_modes = modes
          instance_eval(&block)
        end

        def group(key, &block)
          fail "Undefined parameters group #{key}"\
            unless parameters_groups.key? key
          fail 'method `group` block required' unless block_given?
          self.current_group = key
          instance_eval(&block)
        end

        def switch_list(**options)
          options.each_key do |k|
            options[k] = _t(options[k])
          end
        end
        alias_method :chose_list, :switch_list

        def path(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::Path, name, desc,
                    binary_matcher, **options, &block)
        end

        def string(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::StringParam, name, desc,
                    binary_matcher, **options, &block)
        end

        def flag(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::Flag, name, desc,
                    binary_matcher, **options, &block)
        end

        def switch(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::Switch, name, desc,
                    binary_matcher, **options, &block)
        end

        def chose(name, desc, binary_matcher = nil, **options, &block)
          new_param(Parameters::Chose, name, desc,
                    binary_matcher, **options, &block)
        end

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

        # Stub for skipped parameter
        # TODO may be register skipped parameter?
        def skip(name, desc = '', binary_matcher = nil, **options, &block)
          # nop
        end
      end # SpecDsl
    end
  end
end
