# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      module SpecDsl
        module DslHelpers
          # Translating stub
          def _t(s)
            s
          end

          def defined_modes
            AssLauncher::Enterprise::Cli::DEFINED_MODES
          end
          private :defined_modes

          def described_modes
            @described_modes ||= {}
          end

          def parameters_groups
            @parameters_groups ||= {}
          end

          def parameters
            @parameters ||= Parameters::ParametersList.new
          end

          attr_reader :current_modes
          private :current_modes

          attr_reader :current_group
          private :current_group

          def parents_stack
            @parents_stack ||= []
          end
          private :parents_stack

          def curent_parent
            parents_stack[0]
          end
          private :curent_parent

          def new_param(klass, name, desc, binary_matcher, **options, &block)
            p = klass.new(name, desc, binary_matcher, current_group,
                          current_modes, curent_parent, **options)
            return unless p.match?(binary_wrapper, run_mode)
            parameters << p
            if block_given?
              parents_stack.unshift p
              instance_eval &block
              parents_stack.shift
            end
          end
          private :new_param
        end

        include DslHelpers

        def enterprise_version(v = '0')
          @enterprise_version ||= Gem::Version.new(v)
        end

        def describe_mode(mode, desc, banner)
          fail "Undefined mode: #{mode}" unless defined_modes.include? mode
          described_modes[mode] = {desc: _t(desc), banner: _t(banner)}
        end

        def define_group(name, desc, priority)
          parameters_groups[name.to_sym] = {desc: _t(desc), priority: priority}
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
          @current_modes = modes
          instance_eval &block
        end

        def group(key, &block)
          fail "Undefined parameters group #{key}"\
            unless parameters_groups.key? key
          fail 'method `group` block required' unless block_given?
          @current_group = key
          instance_eval &block
        end

        def switch_list(**options)
          options.each_key do |k|
            options[k] = _t(options[k])
          end
        end
        alias :chose_list :switch_list

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
          options[:value_validator] = Proc.new {fail "FIXME make validate URL string code"}
          new_param(Parameters::StringParam, name, desc,
                    binary_matcher, **options, &block)
        end

        def num(name, desc, binary_matcher = nil, **options, &block)
          options[:value_validator] = Proc.new {fail "FIXME make validate numeric string code"}
          new_param(Parameters::StringParam, name, desc,
                    binary_matcher, **options, &block)
        end

        # Stub for skipped parameter
        # TODO may be register skipped parameter?
        def skip(name, desc = '', binary_matcher = nil, **options, &block)
          #nop
        end
      end # SpecDsl
    end
  end
end
