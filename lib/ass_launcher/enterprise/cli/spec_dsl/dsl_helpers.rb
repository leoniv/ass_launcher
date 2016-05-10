# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      module SpecDsl
        # @api private
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

          attr_accessor :current_modes
          private :current_modes, :current_modes=

          attr_accessor :current_group
          private :current_group, :current_group=

          def parents_stack
            @parents_stack ||= []
          end
          private :parents_stack

          def current_parent
            parents_stack[0]
          end
          private :current_parent

          def new_param(klass, name, desc, binary_matcher, **options, &block)
            p = klass.new(name, desc, binary_matcher, current_group,
                          current_modes, current_parent, **options)
            return unless p.match?(binary_wrapper, run_mode)
            parameters << p
            eval_sub_params(p, &block) if block_given?
          end
          private :new_param

          def eval_sub_params(p, &block)
            parents_stack.unshift p
            instance_eval(&block)
            parents_stack.shift
          end
          private :eval_sub_params
        end
      end
    end
  end
end
