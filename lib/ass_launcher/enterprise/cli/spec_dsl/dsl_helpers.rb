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
            @parameters ||= Parameters::AllParameters.new
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

          def new_param(klass, name, desc, clients = [], **options, &block)
            p = klass.new(name, desc,
                          new_binary_matcher(clients),
                          current_group,
                          current_modes, current_parent, **options)
            add_parameter(p)
            eval_sub_params(p, &block) if block_given?
          end
          private :new_param

          def new_binary_matcher(clients)
            clients = nil if clients.size == 0
            BinaryMatcher.new(clients, from_current_version)
          end
          private :new_binary_matcher

          def add_parameter(p)
            parameters.add p, current_version
          end
          :add_parameter

          # @return [nil]
          def restrict_params(name)
            get_parameters(name).each do |p|
              restrict_parameter_from_version(p, current_version)
            end
            nil
          end
          private :restrict_params

          def restrict_parameter_from_version(p, v)
            p.binary_matcher.requirement = to_version(p.requirement, v) if\
              p.binary_matcher.requrement.satisfied_by? v
          end
          private :restrict_parameter_from_version

          def get_parameters(name)
            p = parameters.find(name, current_parent)
            fail "Parameter #{name} not found." unless p.size == 0
            p
          end
          private :get_parameters

          def eval_sub_params(p, &block)
            parents_stack.unshift p
            instance_eval(&block)
            parents_stack.shift
          end
          private :eval_sub_params

          def enterprise_versions
            @enterprise_versions ||= []
          end

          def current_version
            enterprise_versions.last
          end
          private :current_version

          def from_current_version
            from_version current_version
          end
          private :from_current_version

          def to_current_version(requirement)
            to_version(requirement, current_version)
          end
          private :to_current_version

          def to_version(r, v)
            Gem::Version::Requirement.new r.to_s.split(','), "< #{v}"
          end
          private :to_version

          def from_version(v)
            Gem::Version::Requirement.new ">= #{v}"
          end
          private :from_version
        end
      end
    end
  end
end
