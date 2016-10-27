class String
  def snakize
    gsub(/(.)([A-Z])/,'\1_\2').downcase
  end
end
module TestHelper
  module CliDefSnippets
    require 'clamp'
    module Cmd
      module Colorize
        require 'coderay'
        CodeRay::Encoders::Terminal::TOKEN_COLORS[:comment][:self] = "\e[1;34m"

        def colorize_puts(str)
          $stdout.puts colorize(str)
        end

        def colorize(str)
          return CodeRay.scan(str, :ruby).terminal if colorize?
          str
        end
        private :colorize

        def self.included(klass)
          klass.instance_eval do
            option "--colorize", :flag, "colorize out"
          end
        end
      end

      module SpecDsl
        class AbstractSpecDsl < Clamp::Command
          include Colorize
          option ['-n', '--name'], 'NAME', 'parameter name', required: true

          def self.banner
            "snippet for <#{dsl_method}> DSL method"
          end

          def self.dsl_method
            name.split('::').last.snakize
          end

          def dsl_method
            self.class.dsl_method
          end
        end

        class New < Clamp::Command
          BANNER = 'snippet for specification parameter'
          class Abstract < AbstractSpecDsl
            option ['-s', '--subparameters'], 'SPECS ...',
              'generate reduced snippet'\
              ' for subparameters like "type \'NAME\' ..."' do |s|
              s.split
            end

            option ['-g', '--group'], 'GROUP', 'group of parameter.'\
                ' Uses with --modes' do |s|
              s.downcase.to_sym
            end

            option ['-m', '--modes'], 'MODES ...',
              'run modes for which parameter defined'\
                ' Uses with --group' do |s|
              s.split.map(&:downcase).map(&:to_sym)
            end

            option ['-d', '--desc'], 'DESC', 'parameter description.'

            option ['-c','--clients'], 'CLIENTS ...',
              'clients for which parameter defined' do |s|
              s.split.map(&:to_sym).map(&:downcase)
            end

            option '--validator', :flag,
              'snippet will be generate with :value_validator stub'

            option '--required', :flag,
              'snippet will be generate with option :required => true'

            def args
              r = {}
              r[:name] = name
              r[:subparameters] = subparameters if subparameters
              r[:group] = group if group
              r[:modes] = modes if modes
              r[:desc] = desc if desc
              r[:clients] = clients if clients
              r[:value_validator] = validator? if validator?
              r[:required] = required? if required?
              r
            end

            def execute
              signal_usage_error 'Use --group & --modes together' if\
                (group.nil? ^ modes.nil?)
              begin
                #$stdout.puts\
                colorize_puts\
                  CliDefSnippets::SpecDsl::Param.new(dsl_method, **args)\
                  .to_snippet
              rescue ArgumentError => e
                signal_usage_error e.message
              end
            end
          end

          class String < New::Abstract; end
          class Flag < String; end
          class Path < New::Abstract; end
          class PathExist < New::Abstract; end
          class PathNotExist < New::Abstract; end
          class Url < New::Abstract; end
          class Num < New::Abstract; end
          class Switch < New::Abstract
            option ['-l', '--switch-list'], 'VALUES ...', 'list of accepted values',
              required: true do |s|
              s.split.map(&:to_sym)
            end

            def args
              r = super
              r[:switch_list] = switch_list
              r
            end
          end

          class Chose < New::Abstract
            option ['-l', '--chose-list'], 'VALUES ...', 'list of accepted values',
              required: true do |s|
              s.split.map(&:to_sym)
            end

            def args
              r = super
              r[:chose_list] = chose_list
              r
            end
          end

          DSL_METHODS = {
            'string' => [String.banner, String],
            'flag' => [Flag.banner, Flag],
            'path' => [Path.banner, Path],
            'path_exist' => [Path.banner, PathExist],
            'path_not_exist' => [Path.banner, PathNotExist],
            'url' => [Url.banner, Url],
            'num' => [Num.banner, Num],
            'switch' => [Switch.banner, Switch],
            'chose' => [Chose.banner, Chose]
          }

          DSL_METHODS.each do |k,v|
            subcommand k, *v
          end

#          subcommand 'string', String.banner, String
#          subcommand 'path', Path.banner, Path
#          subcommand 'path_exist', Path.banner, PathExist
#          subcommand 'path_not_exist', Path.banner, PathNotExist
#          subcommand 'url', Url.banner, Url
#          subcommand 'num', Num.banner, Num
#          subcommand 'switch', Switch.banner, Switch
#          subcommand 'chose', Chose.banner, Chose
        end

        class Restrict < AbstractSpecDsl
          BANNER = 'snippet for restrict parameter'

          def execute
            begin
              #$stdout.puts\
              colorize_puts\
                CliDefSnippets::SpecDsl::Restrict.new(name)\
                  .to_s
            rescue ArgumentError => e
              signal_usage_error e.message
            end
          end
        end

        class Change < AbstractSpecDsl
          BANNER = 'snippet for change parameter specification'

          option ['-s', '--subparameters'], 'SPECS ...',
            'generate reduced snippet'\
            ' for subparameters like "type \'NAME\' ..."' do |s|
            s.split
          end

          def args
            r = {}
            r[:name] = name
            r[:subparameters] = subparameters if subparameters
#            r[:group] = group if group
#            r[:modes] = modes if modes
#            r[:desc] = desc if desc
#            r[:clients] = clients if clients
#            r[:value_validator] = validator? if validator?
#            r[:required] = required? if required?
            r
          end

          def execute
            begin
#              colorize_puts\
#                CliDefSnippets::SpecDsl::Restrict.new(name)\
#                .to_s
#              $stdout.puts fail('FIXME')
              colorize_puts\
                CliDefSnippets::SpecDsl::Change.new(name, **args).to_snippet
            rescue ArgumentError => e
              signal_usage_error e.message
            end
          end
        end
      end

      class Main < Clamp::Command
        def self._banner
         'generator snippets on DSL (see AssLauncher::Enterprise::Cli::SpdecDsl)'
        end

        subcommand 'new', SpecDsl::New::BANNER, SpecDsl::New
        subcommand 'restrict', SpecDsl::Restrict::BANNER, SpecDsl::Restrict
        subcommand 'change', SpecDsl::Change::BANNER, SpecDsl::Change
      end
    end

    module SpecDsl
      class Group
        include TestHelper::CliDefValidator
        attr_reader :name
        def initialize(name)
          @name = name
          validate_group if self.class == Group
        end

        def group_name
          name
        end

        def self.dsl_method
          name.split('::').last.snakize
        end

        def dsl_method
          self.class.dsl_method
        end

        def indents
          2
        end

        def indent(inclosure)
          inclosure.gsub(/^/,' ' * indents)
        end

        def dsl_method_args
          ":#{name.to_sym.downcase}"
        end

        def to_s(inclosure = '')
          r = ''
          r << "#{dsl_method} #{dsl_method_args} do\n"
          r << indent(inclosure) + "\n"
          r << 'end'
        end
      end

      class Restrict < Group
        def to_s
          "#{dsl_method} '#{name}'"
        end
      end

      class Mode < Group
        attr_reader :modes
        def initialize(modes)
          @modes = modes
          validate_modes
        end

        def dsl_method_args
          modes.map(&:to_sym).map(&:downcase).to_s.gsub(/(\[|\])/,'')
        end
      end

      class Param < Group
        DEFAULT_ARGS = {
          subparameters: [],
          group: nil,
          modes: nil,
          desc: nil,
          clients: nil,
          value_validator: nil,
          required: nil,
          chose_list: nil,
          switch_list: nil
        }
        def initialize(dsl_method, **args)
          @name = args[:name]
          @dsl_method = dsl_method
          @args = DEFAULT_ARGS.merge args
          validate_clients if clients
        end

        def DSL_METHODS
          Cmd::SpecDsl::New::DSL_METHODS
        end

        def valid_dsl_method(method)
          fail ArgumentError, "Invalid DSL method `#{method}'."\
            " Expects: #{DSL_METHODS().keys.to_s}" unless\
            DSL_METHODS().keys.include? method
          method
        end

        attr_reader :args, :dsl_method

        def to_dsl_method(name)
          signal_usage_error "--subparameters SPECS format:"\
            " `ptype:pname' or `pname'" if name.split(':').size > 2
          return '#FIXME: ptype' if name.split(':').size == 1
          valid_dsl_method name.split(':')[0]
        end

        def subparameters_to_s
          subparameters.map do |name|
            Param.new(to_dsl_method(name),
                      name: name.split(':').last,
                      desc: 'FIXME: description',
                      clients: clients,
                      required: '#FIXME: bool',
                      ).to_snippet
          end.join("\n")
        end

        def method_missing(m, *_)
          fail NoMethodError unless args.key? m
          args[m]
        end

        def switch_list_stub(i)
          list_stub(switch_list, i)
        end

        def chose_list_stub(i)
          list_stub(chose_list, i)
        end

        def list_stub(list, i)
          list.map(&:to_sym).to_s.gsub(/(\[|\])/,'').split(',').map do |item|
            "#{item} => 'FIXME: description'"
          end.join(",#{nl(i)}")
        end

        def nl(i)
          "\n#{' '*i}"
        end

        def dsl_method_args(i)
          r = "'#{name}'"
          r << ", '#{desc}'" if desc
          r << ", #{clients.map(&:to_s).map(&:downcase)
            .to_s.gsub(/(\[|\]|")/,'')}" if clients
          r << ", required: #{required}" if required
          if switch_list
            h = ",#{nl(i)}switch_list: switch_list("
            r << "#{h}#{switch_list_stub(h.size - 3)})"\
          end
          if chose_list
            h = ",#{nl(i)}chose_list: chose_list("
            r << "#{h}#{chose_list_stub(h.size - 3)})"\
          end
          r << ",#{nl(i)}value_validator: proc {|value| fail 'FIXME'}" if\
            value_validator
          r
        end

        def to_s(inclosure = '')
          r = "#{dsl_method} #{dsl_method_args(dsl_method.size + 1)}"
          unless inclosure.empty?
            r << " do\n"
            r << indent(inclosure) + "\n"
            r << 'end'
          end
          r
        end

        def wrrapp(s)
          g = Group.new(group)
          m = Mode.new(modes)
          g.to_s(m.to_s(s))
        end

        def to_snippet
          return wrrapp(to_s(subparameters_to_s)) if group
          to_s(subparameters_to_s)
        end
      end

      class Change < Param
        def subparameters_to_s
          subparameters.map do |name|
            r = ''
            r << Restrict.new(name.split(':').last).to_s
            r << "\n"
            r << Param.new(to_dsl_method(name),
                      name: name.split(':').last,
                      desc: 'FIXME: description',
                      clients: clients,
                      required: '#FIXME: bool',
                      ).to_snippet
            r
          end.join("\n")
        end

        def dsl_method
          :change
        end
      end
    end
  end
end
