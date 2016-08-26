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
        # Options for parameter
        DEFAULT_OPTIONS = {
          required: false,
          value_validator: proc { |value| value },
          switch_list: nil,
          chose_list: nil,
          switch_value: proc { |value| value }
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
        # Options see {DEFAULT_OPTIONS}
        # @return [Hash]
        attr_reader :options

        # Return +true+ if parameter defined for +binary_wrapper+ and +run_mode+
        # @param binary_wrapper [BinaryWrapper::ThickClient
        #  BinaryWrapper::ThinClient WebClient]
        # @param run_mode [Symbol] see {Parameters#modes}
        def match?(binary_wrapper, run_mode)
          binary_matcher.match?(binary_wrapper) && modes.include?(run_mode)
        end

        # Return +true+ if parameter defined for +version+
        # @param version [Gem::Version]
        def match_version?(version)
          binary_matcher.requirement.satisfied_by? version
        end

        # :nodoc:
        def to_sym
          name.downcase.to_sym
        end

        # Returns parameter full name. Full name
        # composed from +full_name+ of all
        # {#parents} parameters
        # @return [String]
        def full_name
          return name if root?
          "#{parent.full_name}#{name}"
        end

        # Array of parent parameters
        # @return [Array]
        def parents
          return [] if root?
          parent.parents << parent
        end

        # Returns deep parameter in hierarchy tree
        # @return [Fixnum]
        def deep
          parents.size
        end

        # Returns +true+ if haven't {#parent} parameter
        def root?
          parent.nil?
        end

        # Returns +true+ if it's child of +expected_parent+ parameter
        # @param expected_parent kinde of [StringParam]
        def child?(expected_parent)
          return false if root?
          parent == expected_parent
        end

        # :nodoc:
        def to_s
          name.to_s
        end

        # Returns self with +value+ as 1C:Enterprise CLI argumets array
        # @example
        #  param.name #=> "/Parm"
        #  param.to_args 'value' #=> ["/Param", "value"]
        # @return [Array<String>]
        def to_args(value)
          [key(value).to_s, value(value).to_s]
        end

        # Wrapper for {#options}
        def switch_list
          options[:switch_list]
        end

        # (see #switch_list)
        def chose_list
          options[:chose_list]
        end

        # (see #switch_list)
        def value_validator
          options[:value_validator]
        end

        # (see #switch_list)
        def required?
          options[:required]
        end

        def key(_value)
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

        # Builds usage message
        def usage
          fail NotImplementedError
        end

        def auto_binary_matcher(arg)
          return arg if arg.is_a? BinaryMatcher
          return BinaryMatcher.auto(modes, arg) if arg.is_a? String
          BinaryMatcher.auto modes
        end
        private :auto_binary_matcher

        # Array of subparameters
        # @return [Array]
        def childs
          @childs ||= []
        end

        # Add subparameter into {#childs} array
        # @param param kinde of {StringParam}
        def add_child(param)
          childs << param
        end

        # Restricts parameter from +version+
        # and do it recursively for all subparameters from {#childs} array
        # @param (see #match_version?)
        def restrict_from(version)
          restrict_childs(version)
          binary_matcher.requirement =
            restrict_v(binary_matcher.requirement,
                       version) if match_version? version
        end

        def restrict_childs(version)
          childs.each do |p|
            p.restrict_from version
          end
        end
        private :restrict_childs

        def restrict_v(r, v)
          Gem::Version::Requirement.new r.to_s.split(','), "< #{v}"
        end
        private :restrict_v

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
          # @param parent kinde of {StringParam} parent for subpurameter
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
            @parent.add_child(self) unless parent.nil?
          end

          # Parameter require argumet
          def argument_require
            true
          end
        end

        # Parameter expects filesystem path
        # Path string cam came from diferent sources
        # and have windows, unix or unix-cygwin format
        # It class instance make path string platform independet use
        # {AssLauncher::Support::Platforms::PathExtension} class
        class Path < StringParam
          # Extends for {Parameters::DEFAULT_OPTIONS}.
          #
          # Option: +:mast_be+ expects +:exist+ or +:not_exist+ values.
          #
          # If +:exist+ given verified for path must be exists and
          # if +:not_exist+ given verified for pat must be not exists
          DEFAULT_OPTIONS = Parameters::DEFAULT_OPTIONS.merge(mast_be: nil)
          include AssLauncher::Support::Platforms

          def default_options
            DEFAULT_OPTIONS
          end
          private :default_options

          # (see #switch_list)
          def mast_be
            options[:mast_be]
          end

          def value(value)
            validate(value)
            path = platform.path(value).realdirpath
            verify(path)
            path.to_s
          end
          private :value

          def verify(path)
            case mast_be
            when :exist then mast_exists(path)
            when :not_exist then mast_not_exists(path)
            end
          end
          private :verify

          def mast_exists(path)
            fail ArgumentError, "Wrong value for #{name}."\
              " Path #{path} not exists" unless path.exist?
          end
          private :mast_exists

          def mast_not_exists(path)
            fail ArgumentError, "Wrong value for #{name}."\
              " Path #{path} exists" if path.exist?
          end
          private :mast_not_exists
        end

        # Chose parameter expects argunment value from chose_list
        class Chose < StringParam
          def validate(value)
            fail ArgumentError, "Wrong value `#{value}' for #{name} parameter"\
              unless chose_list.key? value.to_sym
          end
          private :validate
        end

        # Flag parameter not expects argument
        class Flag < StringParam
          # Returns self as 1C:Enterprise CLI argumets array like
          # +["/Flag", ""]+
          # @param _ [nil] {Flag} not expects argument
          # @return (see StringParam#to_args)
          def to_args(_ = nil)
            super ''
          end

          # Parameter not require argument
          def argument_require
            false
          end
        end

        # Switch parameter is most stupid CLI parameter of 1C:Enterprise.
        # Switch parameter expects argument value from +:switch_list+ or
        # block +:switch_value+ which return modified value argument.
        # Switch parameter modifyed self name when uses parameter value
        # @example
        #  # /UseHwLicenses have {:+=>'',:-=>''} switch_list and:
        #   to_args(:+) # => ['/UseHwLicenses+','']
        #   to_args(:-) # => ['/UseHwLicenses-','']
        #   to_args(:bad_value) # => ArgumentError
        #
        #  # -TimeLimit have block:
        #   {switch_value: ->(value) { ":#{value}"}}
        #  # and
        #   to_args("12:00") # => ['-TimeLimit:12:00','']
        class Switch < StringParam
          def value(_value)
            ''
          end
          private :value

          def key(value)
            "#{name}#{switch_value(value)}"
          end
          private :key

          def switch_value(value)
            if switch_list
              fail ArgumentError, "Wrong value #{value} for parameter #{name}"\
                unless switch_list.key? value.to_sym
            end
            validate(value)
            options[:switch_value].call(value)
          end
          private :switch_value
        end

        # List of parameters defined for one version
        # @raise (see #<<)
        class ParametersList
          # Array of parameters.
          # For add parameter into array use {#<<}
          def parameters
            @parameters ||= []
          end

          # Returns +true+ if parameter +p+ presents in list
          # @param p kinde of {StringParam}
          def param_defined?(p)
            !find(p.name, p.parent).nil?
          end

          # Add parameter in to tail of list
          # @param p [StringParam Flag Path Switch Chose] parameter instance
          # @raise [ArgumentError] if parameter alrady present in list
          def <<(p)
            fail ArgumentError,
                 "Parameter #{p.full_name} alrady defined" if\
                    param_defined?(p)
            parameters << p
          end
          alias_method :"+", :"<<"
          alias_method :add, :"<<"

          # Find parameter in list
          # @param name [String] name of finded parameter
          # @param parent [StringParam Flag Path Switch Chose] parent for
          #  subparameter
          # @return [StringParam Flag Path Switch Chose nil] founded parameter
          def find(name, parent)
            parameters.each do |p|
              if p.to_sym == name.downcase.to_sym &&
                 p.parent == parent
                return p
              end
            end
            nil
          end

          # :nodoc:
          def each(&block)
            parameters.each(&block)
          end

          # (see Parameters#usage)
          def usage
            fail NotImplementedError
          end
        end

        # List of parameters defined for all versions
        # @raise (see #add)
        class AllParameters
          # Array of parameters.
          # For add parameter into array use {#add}
          def parameters
            @parameters ||= []
          end

          # Add parameter into list
          # @param (see #param_defined?)
          # @raise [ArgumentError] if parameter +p.name+ alrady defined for
          #  +version+
          def add(p, version)
            fail_if_difined(p, version)
            parameters << p
          end

          def fail_if_difined(p, version)
            fail ArgumentError,
                 "Parameter #{p.full_name} alrady defined for version"\
                 " #{version}" if param_defined? p, version
          end
          private :fail_if_difined

          # Returns +true+ if parameter +p+ for +version+ presents in list
          # @param p kinde of {StringParam}
          # @param version (see Parameters#match_version?)
          def param_defined?(p, version)
            find(p.name, p.parent).each do |p_|
              return true if p_.match_version? version
            end
            false
          end

          # Return parameters list for given +binary_wrapper+ and +run_mode+
          # @return [ParametersList] for given +binary_wrapper+ and +run_mode+
          # @param (see Parameters#match?)
          def to_parameters_list(binary_wrapper, run_mode)
            r = new_list
            parameters.each do |p|
              r << p if p.match? binary_wrapper, run_mode
            end
            r
          end

          def new_list
            ParametersList.new
          end
          private :new_list

          # Find actual parameter for +version+
          # @return kinde of {StringParam}
          # @param name (see #find)
          # @param parent (see #find)
          # @param version [Gem::Version]
          def find_for_version(name, parent, version)
            r = nil
            find(name, parent).each do |p|
              r = oops!(r, p, version) if p.match_version? version
            end
            r
          end

          def oops!(r, p, v)
            fail "Too many params #{p.full_name} spec for #{v}" unless r.nil?
            p
          end
          private :oops!

          # Find all parameter versions
          # @param name (see StringParam#initialize)
          # @param parent (see StringParam#initialize)
          # @return [Array] of parameters
          def find(name, parent)
            parameters.select do |p|
              p.to_sym == name.downcase.to_sym &&
                p.parent == parent
            end
          end
        end
      end
    end
  end
end
