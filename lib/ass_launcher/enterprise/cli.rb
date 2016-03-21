# encoding: utf-8

module AssLauncher
  class Configuration
    def platform_cli_spec
      @platform_cli_spec ||= Enterprise::Cli::CliSpec.load
    end
  end
  module Enterprise
    module Cli
      DEFINED_MODES = [
        :createinfobase,
        :enterprise,
        :designer
      ].freeze
      require 'ass_launcher/enterprise/cli/arguments_builder'
      class CliSpec
        def self.loader(binary, run_mode)
          Class.new do
            include AssLauncher::Enterprise::Cli::SpecDsl
            attr_reader :run_mode, :binary_wrapper
            def initialize(binary_wrapper, run_mode)
              @binary_wrapper = binary_wrapper
              @run_mode = run_mode
            end
            def dup
              self.class.new(binary_wrapper, run_mode)
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

        attr_reader :parameters
        attr_reader :modes
        attr_reader :groups

        def initialize(parameters, modes, groups)
          @parameters = parameters
          @modes = modes
          @groups = groups
        end

        def self.for(binary, run_mode)
          loader(binary, run_mode).instance_eval\
            AssLauncher.config.platform_cli_spec
          new(loader.parameters,
              loader.described_modes,
              loader.parameters_groups)
        end
      end

      # @api private
      class BinaryMatcher
        def initialize(client = :all, version = '>= 0')
          @client = client.to_sym
          @requirement = Gem::Requirement.new version
        end

        def match?(binary_wrapper)
          match_client(binary_wrapper) && match_version(binary_wrapper)
        end

        private
        def match_client(bw)
          return true if @client == :all
          @client == bw.class.name.to_s.downcase.gsub(/client$/,'').to_sym
        end

        def match_version(bw)
          @requirement.satisfied_by? bw.version
        end
      end

      module Parameters
        class String

          DEFULT_OPTIONS = {
            required: false,
            value_validator: Proc.new {|value|},
            switch_list: nil,
            chose_list: nil,
            switch_value: Proc.new {|value| value}
          }.freeze

          attr_reader :name
          attr_reader :desc
          attr_reader :binary_matcher
          attr_reader :group
          attr_reader :modes
          attr_reader :parent

          # @api private
          def initialize(name, desc, binary_matcher,
                         group, modes, parent = nil, **options)
            @name = name
            @desc = desc
            @binary_matcher = binary_matcher || BinaryMatcher.new
            @group = group
            @modes = modes || Cli::DEFINED_MODES
            @options = DEFAULT_OPTIONS.merge options
            @parent = parent
          end

          def match?(binary_wrapper, run_mode)
            binary_mather.match? binary_wrapper && modes.include?(run_mode)
          end

          def to_sym
            name.downcase.to_sym
          end

          def full_name
            return name if root?
            "#{parent.full_name}#{name}"
          end

          def parents
            return [] if root?
            parent.parents << parent
          end

          def deep
            parents.size
          end

          def root?
            parent.nil?
          end

          def child?(parent)
            return false if root?
            parent() == parent
          end

          def to_s
            name.to_s
          end

          def to_args(value)
            [key(value), value(value)]
          end

          def key(value)
            name
          end
          private :key

          def validate(value)
            value_validator.call value
          end

          def value(value)
            validate(value)
            value
          end
          private :value
        end

        class Path < String
          include AssLauncher::Support::Platforms
          def value(value)
            platform.path(value).to_s
          end
        end

        class Chose < String
          def validate(value)
            fail ArgumentError, "Wrong value #{value} for #{name} parameter"\
              unless chose_list.key? value.to_sym
          end

          def chose_list
            options[:chose_list]
          end
        end

        class Flag < String
          def value(value)
            ''
          end
        end

        class Switch < Flag
          def key(value)
            "#{name}#{switch_value(value)}"
          end

          def switch_value(value)
            if switch_list
              fail ArgumentError, "Wrong value #{value} for parameter #{name}"\
                unless switch_list.key? value.to_sym
            end
            options.switch_value.call(validate(value))
          end

          def switch_list
            options[:switch_list]
          end
        end
      end

      class ParamtersList
        def initialize
          @parameters = []
        end

        def defined?(p)
          ! find(p.name, p.parent).nil?
        end

        def <<(p)
          fail ArgumentError, "Parameter #{p.full_name} alrady defined"\
            if defined?(p)
          @parameters << p
        end
        alias :"+" :"<<"
        alias :add :"<<"

        def find(name, parent)
          parameters.each do |p|
            return p if (p.root? || p.child?(parent))\
              && p.to_sym == name.downcase.to_sym
          end
        end

        def each(&block)
          parameters.each &block
        end
      end

      module SpecDsl
        def thick_client(v = '>= 0')
          BinaryMatcher.new(:thick, v)
        end

        def thin_client(v = '>= 0')
          BinaryMatcher.new(:thin, v)
        end

        def all_client(v = '>= 0')
          BinaryMatcher.new(:all, v)
        end

        def parameters
          @parameters ||= ParamtersList.new
        end

        def define(parameter, &block)
          parameters.define(parameter, &block)
        end
        private :define

        def mode(modes, &block)
          raise 'FIXME'
        end
      end # SpecDsl
    end
  end
end
