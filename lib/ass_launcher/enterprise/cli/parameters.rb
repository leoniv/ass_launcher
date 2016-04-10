# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      # 1C Enterprise cli parameters
      # Fuckin 1C have very obscure cli api
      # Parameters may have subparameters. All parameters and subparameters
      # expects argument or not. Some parameters may be modified with + or - or
      # other values like this: /Parm or /Param+ or /Param- or /Param:date:time.
      #
      # For implement binding parameters and subparameters, parameter have
      # +parent+ propery. If +parent+ property is +nil+ it is root parameter
      # and subpurameter if else
      module Parameters
        DEFAULT_OPTIONS = {
          required: false,
          value_validator: Proc.new {|value|},
          switch_list: nil,
          chose_list: nil,
          switch_value: Proc.new {|value| value}
        }.freeze

        # Parameter name like it define in 1C cli api
        # Name may start with '/' or '-' key. Example: /Parameter or
        # -subpurameter
        # @return string
        attr_reader :name
        # Parameter help message
        # @return string
        attr_reader :desc
        # 1C binary type and version for which parameter defined
        # @return [BinaryMatcher]
        # @api private
        attr_reader :binary_matcher
        # Parameter group for build cli api help
        # @return [Symbol]
        attr_reader :group
        # 1C binary run mode for which parameter defined. see
        # {Cli::DEFINED_MODES}
        # @return [Array<Symbol>]
        attr_reader :modes
        # Parent parameter for subpurameter
        # @return kinde of [String]
        attr_reader :parent

        def match?(binary_wrapper, run_mode)
          binary_matcher.match?(binary_wrapper) && modes.include?(run_mode)
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

        def switch_list
          options[:switch_list]
        end

        def chose_list
          options[:chose_list]
        end

        def key(value)
          name
        end
        private :key

        def validate(value)
          value_validator.call value
        end
        private :validate

        def value(value)
          validate(value)
          value
        end
        private :value

        def def_options
          DEFAULT_OPTIONS
        end
        private :def_options

        def usage
          raise NotImplementedError
        end

        # Parameter expects string value
        class StringParam
          include Parameters
          # @api private
          # @param name [String] name of parameter like defined 1C cli api
          # @param desc [String] help description
          # @param binary_matcher [BinaryMatcher, String, nil] for which
          #  parameter defined
          #  - If nil will be build default matcher.
          #  - If string. String value mast be suitable for Gem::Requirement.
          #    In this case, will be build matcher for version defined in
          #    string and suitable bynary type detected on run_modes
          # @param group [Symbol] parameter group
          # @param modes [Array] run modes for which parameter defined
          # @param parent kinde of [StringParam] parent for subpurameter
          # @param options [Hash] see {Parameters::DEFAULT_OPTIONS}
          def initialize(name, desc, binary_matcher,
                         group, modes, parent = nil, **options)
            @name = name
            @desc = desc
            @modes = modes || Cli::DEFINED_MODES
            @binary_matcher = auto_binary_matcher(binary_matcher)
            @group = group
            @options = def_options.merge options
            @parent = parent
          end

          def auto_binary_matcher(arg)
            return arg if arg.is_a? BinaryMatcher
            return BinaryMatcher.new(auto_client, arg) if arg.is_a? String
            BinaryMatcher.new auto_client
          end
          private :auto_binary_matcher

          def auto_client
            return :thick if (@modes.include?(:createinfobase) ||\
              @modes.include?(:designer))
            :all
          end
          private :auto_client
        end

        # Parameter expects filesystem path
        # Path string cam came from diferent sources
        # and have windows, unix or unix-cygwin format
        # It class instance make path string platform independet use
        # {AssLauncher::Support::Platforms::PathExtension} class
        class Path < StringParam
          include AssLauncher::Support::Platforms
          private
          def value(value)
            platform.path(value).to_s
          end
        end

        # Chose parameter expects argunment value from chose_list
        class Chose < StringParam
          def validate(value)
            fail ArgumentError, "Wrong value #{value} for #{name} parameter"\
              unless chose_list.key? value.to_sym
          end
          private :validate
        end

        # Flag parameter not expects argument
        class Flag < StringParam
          private
          def value(value)
            ''
          end
        end

        # Switch parameter expects argument value from switch_list or
        # block switch_value which return modified value argument.
        # Switch parameter modifyed self name when set 1C cli value
        # @example
        #  # /UseHwLicenses have {:"+"=>'',:"-"=>''} switch_list and:
        #   to_args(:"+") # => ['/UseHwLicenses+','']
        #   to_args(:"-") # => ['/UseHwLicenses-','']
        #   to_args(:"bad value")i # => ArgumentError
        #
        #  # -TimeLimit have block:
        #   switch_value: =>{|value|; ":#{value}"}
        #  # and
        #   to_args("12:00") #=> ['-TimeLimit:12:00','']
        class Switch < Flag
          def key(value)
            "#{name}#{switch_value(value)}"
          end
          private :key

          def switch_value(value)
            if switch_list
              fail ArgumentError, "Wrong value #{value} for parameter #{name}"\
                unless switch_list.key? value.to_sym
            end
            options.switch_value.call(validate(value))
          end
          private :switch_value
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

          def usage
            raise NotImplementedError
          end
        end
      end
    end
  end
end
