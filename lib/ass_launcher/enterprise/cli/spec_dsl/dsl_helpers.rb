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

          def new_param(klass, name, desc, clients = [], options = {}, &block)
            fail 'Group must be specifed' if current_group.nil?
            fail 'Modes must be specifed' if current_modes.nil?
            p = klass.new(name, desc,
                          new_binary_matcher(clients),
                          current_group,
                          current_modes, current_parent, **options)
            add_parameter(p)
            eval_sub_params(p, &block) if block_given?
          end
          private :new_param

          def new_binary_matcher(clients)
            return (inherid_binary_matcher || auto_binary_matcher) if\
              clients.size == 0
            BinaryMatcher.new(clients, from_current_version)
          end
          private :new_binary_matcher

          def auto_binary_matcher
            BinaryMatcher.auto(current_modes, from_current_version)
          end
          private :auto_binary_matcher

          def inherid_binary_matcher
            current_parent.binary_matcher if\
              current_parent
          end
          private :inherid_binary_matcher

          def change_param(name, &block)
            p = get_parameter(name)
            old_g = current_group
            old_m = current_modes
            self.current_group = p.group
            self.current_modes = p.modes
            eval_sub_params(p, &block) if block_given?
            self.current_group = old_g
            self.current_modes = old_m
          end
          private :change_param

          def get_parameter(name)
            p = parameters.find_for_version(name,
                                            current_parent,
                                            current_version)
            fail "Parameter #{name} not found for #{current_version}." unless p
            p
          end
          private :get_parameter

          def add_parameter(p)
            parameters.add p, current_version
          end
          private :add_parameter

          # @return [nil]
          def restrict_params(name, v)
            get_parameters(name).each do |p|
              p.restrict_from(v)
            end
            nil
          end
          private :restrict_params

          def get_parameters(name)
            p = parameters.find(name, current_parent)
            fail "Parameter #{name} not found." if p.size == 0
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

          def add_enterprise_versions(v)
            fail ArgumentError, 'Invalid version sequences. Expects version >'\
              " #{current_version} but given #{v}" unless v > current_version
            enterprise_versions << v
          end
          private :add_enterprise_versions

          def reset_all
            reset_group
            reset_modes
          end
          private :reset_all

          def reset_group
            self.current_group = nil
          end
          private :reset_group

          def reset_modes
            self.current_modes = nil
          end
          private :reset_modes

          def current_version
            return Gem::Version.new('0') if enterprise_versions.last.nil?
            enterprise_versions.last
          end
          private :current_version

          def from_current_version
            from_version current_version
          end
          private :from_current_version

          def from_version(v)
            Gem::Version::Requirement.new ">= #{v}"
          end
          private :from_version
        end
      end
    end
  end
end
