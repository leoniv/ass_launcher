require 'clamp'
module AssLauncher
  # AssLauncher command-line untils
  # @example
  #   $ass-launcher --help
  # @api private
  #
  module Cmd
    # Colorize string for console output
    # It's stupid wrapper for ColorizedString
    # @api private
    module Colorize
      require 'colorized_string'

      # rubocop:disable Style/MethodMissing
      def self.method_missing(m, s)
        colorized(s).send(m)
      end
      # rubocop:enable Style/MethodMissing

      def self.colorized(mes)
        ColorizedString[mes]
      end
    end

    # @api private
    module Support
      # Mixin
      # @api private
      module SrvStrParser
        # Parse string like +user:password@host:port+
        # @param s [String]
        # @return [Array] ['host:port', 'user', 'password']
        def parse_srv_str(s)
          split = s.split('@')
          fail ArgumentError if split.size > 2

          host = split.pop
          return [host, nil, nil] if split.size.zero?

          split = split[0].split(':')
          fail ArgumentError if split.size > 2

          user = split.shift
          pass = split.shift

          [host, user, pass]
        end
      end

      # Mixin for validate version
      # @api private
      module VersionValidator
        include AssLauncher::Enterprise::CliDefsLoader

        def validate_version
          return known_version.sort.last if version.to_s.empty?
          unless known_version.include? version
            signal_usage_error "Unknown 1C:Enterprise v#{version}\n"\
              "Execute `ass-launcher show-version' command"
          end
          version
        end

        def known_version
          @known_version ||= defs_versions.sort
        end
      end

      # Mixin for cli reporters
      # @api private
      module AcceptedValuesGet
        def accepted_values_get
          xxx_list_keys(:switch, param) + xxx_list_keys(:chose, param)
        end

        def xxx_list_keys(list, p)
          list = p.send("#{list}_list".to_sym)
          return list.keys if list
          []
        end
      end
    end

    # @api private
    # Abstract things
    module Abstract
      # Abstarct subcommand
      # @api private
      class SubCommand < Clamp::Command
        # :nodoc:
        module Declaration
          def subcommand_(klass)
            subcommand(klass.command_name, klass._banner, klass)
          end

          def declare_subcommands
            self::SubCommands.constants.each do |c|
              subcommand_ self::SubCommands.const_get(c)
            end
          end
        end

        extend Declaration

        # :nocov:
        def self.command_name
          fail 'Abstract'
        end

        def self._banner
          fail 'Abstract'
        end
        # :nocov:
      end

      # Mixin
      # @api private
      module ClientMode
        def parrent_command
          invocation_path.to_s.split[1]
        end

        def client
          case parrent_command
          when 'designer' then :thick
          when 'thick' then :thick
          when 'thin' then :thin
          when 'web' then :web
          when 'makeib' then :thick
          end
        end

        def mode
          case parrent_command
          when 'designer' then :designer
          when 'thick' then :enterprise
          when 'thin' then :enterprise
          when 'web'  then :webclient
          when 'makeib' then :createinfobase
          end
        end
      end

      # Mixin
      # @api private
      module BinaryWrapper
        include AssLauncher::Api
        include ClientMode

        def self.included(base)
          fail "#{base} must include Option::Arch module before include"\
            ' BinaryWrapper' unless base.include? Option::Arch
        end

        def binary_wrapper
          binary_get || (fail Clamp::ExecutionError
            .new(not_inst_message, invocation_path, 1))
        end

        def not_inst_message
          "1C:Enterprise #{client} v #{vrequrement} not installed"
        end
        private :not_inst_message

        def vrequrement
          return '' unless version
          case version.segments.size
          when 3 then "~> #{version}.0"
          when 2 then "~> #{version}.0"
          else "= #{version}"
          end
        end

        def binary_get
          case client
          when :thick then thicks_get(vrequrement).last
          when :thin then thins_get(vrequrement).last
          end
        end
        private :binary_get

        def thicks_get(req)
          thicks(req).select do |bw|
            arch_any? || bw.arch == arch
          end
        end
        private :thicks_get

        def thins_get(req)
          thins(req).select do |bw|
            arch_any? || bw.arch == arch
          end
        end
        private :thins_get

        # rubocop:disable all
        def dry_run(cmd)
          r = "#{cmd.cmd.gsub(' ', '\\ ')} "
          if mode == :createinfobase
            r << cmd.args.join(' ')
          else
            r << cmd.args.map do |a|
              unless a =~ %r{^(/|-|'|"|DESIGNER|ENTERPRISE)}
                "\'#{a}\'" unless a.to_s.empty?
              else
                a
              end
            end.join(' ')
          end
        end

        def run_enterprise(cmd)
          if respond_to?(:dry_run?) && dry_run?
            puts Colorize.yellow(dry_run(cmd))
          else
            begin
              cmd.run.wait.result.verify!
            rescue AssLauncher::Support::Shell::RunAssResult::RunAssError => e
              raise Clamp::ExecutionError.new(e.message, invocation_path, 1)
            end
          end
          cmd
        end
        # rubocop:enable all
      end

      # @api private
      module Option
        # Mixin
        # Command option
        module SearchPath
          def self.included(base)
            base.option %w[--search-path -I], 'PATH',
                        'specify 1C:Enterprise installation path' do |s|
              AssLauncher.config.search_path = s
              s
            end
          end
        end

        # Mixin
        # Command option
        module Version
          def self.included(base)
            base.option %w[--version -v], 'VERSION',
                        "specify 1C:Enterprise version requiremet.\n"\
                        " Expected full version number or only major\n"\
                        ' part of version number' do |s|
              Gem::Version.new(s)
            end
          end
        end

        # Mixin
        # Command option
        module Verbose
          def self.included(base)
            base.option '--verbose', :flag, 'show more information'
          end
        end

        # Mixin
        # Command option
        module Query
          def self.included(base)
            base.option %w[--query -q], 'REGEX',
                        'regular expression based filter' do |s|
              begin
                Regexp.new(s, Regexp::IGNORECASE)
              rescue RegexpError => e
                fail ArgumentError, e.message
              end
            end
          end
        end

        # Mixin
        # Command option
        module Dbms
          # rubocop:disable all
          def self.included(base)
            dbtypes = AssLauncher::Support::ConnectionString::DBMS_VALUES\
              + ['File']

            define_method :valid_db_types do
              dbtypes
            end

            base.option '--dbms', 'DB_TYPE',
                        "db type: #{dbtypes}.\nValue \"File\""\
                        ' for make file infobase', default: 'File' do |s|
              raise ArgumentError,
                "valid values: [#{valid_db_types.join(' ')}]" unless\
                valid_db_types.include? s
              s
            end
          end
          # rubocop:enable all
        end

        # Mixin
        # Command option
        module Dbsrv
          attr_reader :dbsrv_user, :dbsrv_pass, :dbsrv_host
          include Support::SrvStrParser
          def parse_dbsrv(s)
            @dbsrv_host, @dbsrv_user, @dbsrv_pass = parse_srv_str(s)
          end

          def self.included(base)
            base.option '--dbsrv', 'user:pass@dbsrv', 'db server address' do |s|
              parse_dbsrv s
              s
            end
          end
        end

        # Mixin
        # Command option
        module Esrv
          attr_reader :esrv_user, :esrv_pass, :esrv_host
          include Support::SrvStrParser
          def parse_esrv(s)
            @esrv_host, @esrv_user, @esrv_pass = parse_srv_str(s)
          end

          def self.included(base)
            base.option '--esrv', 'user:pass@esrv',
                        'enterprise server address' do |s|
              parse_esrv(s)
              s
            end
          end
        end

        # Mixin
        # Command option
        module User
          def self.included(base)
            base.option %w[--user -u], 'NAME', 'infobase user name'
          end
        end

        # Mixin
        # Command option
        module Password
          def self.included(base)
            base.option %w[--password -p], 'PASSWORD', 'infobase user password'
          end
        end

        # Mixin
        # Command option
        module Pattern
          def self.included(base)
            base.option %w[--pattern -P], 'PATH',
                        'Template for make infobase.'\
                        ' Path to .cf, .dt files' do |s|
              fail ArgumentError, "Path not exist: #{s}" unless File.exist?(s)
              s
            end
          end
        end

        # Mixin
        # Command option
        module Uc
          def self.included(base)
            base.option '--uc', 'LOCK_CODE', 'infobase lock code'
          end
        end

        # Mixin
        # Command option
        module DryRun
          def self.included(base)
            base.option %w[--dry-run], :flag,
                        'will not realy run 1C:Enterprise only puts cmd string'
          end
        end

        # Mixin
        # Command option
        module Raw
          def parse_raw(s)
            split = s.split(%r{(?<!\\),\s}).map(&:strip)

            split.map do |pv|
              fail ArgumentError, "Parse error in: #{pv}" unless\
                pv =~ %r{^(/|-)}
              pv =~ %r{^(\/|-)([^\s]+)+(.*)?}
              ["#{$1}#{$2}", $3.strip].map { |i| i.gsub('\\,', ',') }
            end
          end

          def raw_param
            r = []
            raw_list.each do |params|
              r += params
            end
            r
          end

          def self.included(base)
            description = "other 1C CLI parameters in raw(native) format.\n"\
              'Parameters and their arguments must be delimited'\
              " comma-space sequence: `, '\n"\
              "If values includes comma comma must be slashed `\\\\,'\n"\
              'WARNING: correctness of parsing will not guaranteed!'

            base.option '--raw', '"/Par VAL, -SubPar VAL"', description,
                        multivalued: true do |s|
              parse_raw s
            end
          end
        end

        # Mixin
        # Command option
        module ShowAppiaredOnly
          def self.included(base)
            base.option ['--show-appiared-only', '-a'], :flag,
                        'show parameters which appiared in --version only'
          end
        end

        # Mixin
        # Command option
        module DevMode
          def self.included(base)
            base.option ['--dev-mode', '-d'], :flag,
                        "for developers mode. Show DSL methods\n"\
                        " specifications for builds commands in ruby scripts\n"
          end
        end

        # Mixin
        # Command option
        module Format
          def self.included(base)
            base.option ['--format', '-f'], 'ascii|csv', 'output format',
                        default: :ascii do |s|
              fail ArgumentError, "Invalid format `#{s}'" unless\
                %w[csv ascii].include? s
              s.to_sym
            end
          end
        end

        # Mixin
        # Command option
        module Arch
          def expected_archs
            [AssLauncher::Enterprise::BinaryWrapper::X86_64,
             AssLauncher::Enterprise::BinaryWrapper::I386]
          end

          def self.included(base)
            base.option '--arch', 'ARCH',
              'specify x86_64 or i386 platform arch' do |s|
              fail ArgumentError, "Invalid arch `#{s}'."\
                " Valid values #{expected_archs.join('|')}" unless\
                expected_archs.include? s
              s
            end
          end

          def x86_64?
            arch.to_s == AssLauncher::Enterprise::BinaryWrapper::X86_64
          end

          def arch_any?
            arch.nil?
          end
        end
      end

      # @api private
      # rubocop:disable Style/ClassAndModuleCamelCase
      module Parameter
        # Mixin
        # Command parameter
        module IB_PATH
          def self.included(base)
            base.parameter 'IB_PATH', 'path to infobase like a strings'\
                            " 'tcp://srv/ref' or 'http[s]://host/path'"\
                            " or 'path/to/ib'", attribute_name: :ib_path do |s|
              s
            end
          end
        end

        # Mixin
        # Command parameter
        module IB_PATH_NAME
          def self.included(base)
            base.parameter 'IB_PATH | IB_NAME',
                           'PATH for file or NAME for server infobase',
                           attribute_name: :ib_path do |s|
              s
            end
          end
        end
      end
      # rubocop:enable Style/ClassAndModuleCamelCase

      # Abstarct cli-help command
      # @api private
      class Cli < SubCommand
        include Support::VersionValidator
        include Option::Version
        include Option::ShowAppiaredOnly
        include Option::DevMode
        include Option::Query
        include Option::Format
        include Option::Verbose
        include ClientMode

        # Reporter
        # @api private
        # rubocop:disable Metrics/ClassLength
        class Report
          USAGE_COLUMNS = [:usage,
                           :argument,
                           :parent,
                           :group,
                           :desc].freeze

          DEVEL_COLUMNS = [:parameter,
                           :dsl_method,
                           :accepted_values,
                           :parent,
                           :param_klass,
                           :group,
                           :require,
                           :desc].freeze

          # Report's row
          class Row
            include Support::AcceptedValuesGet

            (USAGE_COLUMNS + DEVEL_COLUMNS).uniq.each do |col|
              attr_accessor col
            end

            attr_reader :param
            def initialize(param)
              @param = param
              fill
            end

            # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
            # rubocop:disable Metrics/MethodLength
            def fill
              self.parameter = basic_usage
              self.dsl_method = dsl_method_get
              self.parent = param.parent
              self.require = param.binary_matcher.requirement
              self.accepted_values = accepted_values_get
                .to_s.gsub(/(^\[|\]$)/, '')
              self.usage, self.argument = usage_full
              self.desc = param.desc
              self.param_klass = param.class.name.split('::').last
              self.group = param.group
            end
            private :fill

            def usage_full
              case param.class.name.split('::').last
              when 'Switch' then
                ["#{basic_usage}(#{accepted_values_get.join('|')})"]
              when 'Chose' then
                [basic_usage, accepted_values_get.join(', ')]
              when 'StringParam' then [basic_usage, 'VALUE']
              when 'Path' then [basic_usage, 'PATH']
              when 'Flag' then [basic_usage]
              when 'PathTwice' then [basic_usage, 'PATH PATH']
              else basic_usage
              end
            end
            # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
            # rubocop:enable Metrics/MethodLength

            def basic_usage
              return "  #{param.name}" if param.parent
              param.name
            end

            def dsl_method_get
              method = param.name.gsub(%r{^\s*(/|-)}, '_')
              return "  #{method}" if param.parent
              method
            end

            def to_csv(columns)
              r = ''
              columns.each do |col|
                r << "\"#{send(col).to_s.tr('"', '\'')}\";"
              end
              r.gsub(/;$/, '')
            end
          end

          attr_reader :client, :mode, :version, :query, :appiared_only,
                      :dev_mode
          # rubocop:disable Metrics/ParameterLists
          def initialize(client, mode, version, appiared_only, query, dev_mode)
            @client = client
            @mode = mode
            @version = version
            @appiared_only = appiared_only
            @query = query
            @dev_mode = dev_mode
          end
          # rubocop:enable Metrics/ParameterLists

          def clients?(p)
            p.binary_matcher.clients.include? client
          end

          def modes?(p)
            p.modes.include? mode
          end

          def version?(p)
            return true if version.nil?
            if appiared_only
              p.binary_matcher.requirement.to_s =~ /^>=\s*#{version}/
            else
              p.match_version?(version) unless appiared_only
            end
          end

          def match?(p)
            clients?(p) && modes?(p) && version?(p)
          end

          def not_filtred?(p)
            return true unless query
            coll_match?(:desc, p) || coll_match?(:parent, p) || \
              coll_match?(:name, p)
          end

          def coll_match?(prop, p)
            !(p.send(prop).to_s =~ query).nil?
          end

          def groups
            AssLauncher::Enterprise::Cli::CliSpec.cli_def.parameters_groups
          end

          def grouped_rows
            r = {}
            groups.each do |gname, _|
              r[gname] = rows.select { |row| row.group == gname }
                .sort_by { |row| row.param.full_name }
            end
            r
          end

          def rows
            @rows ||= execute
          end

          def select_parameters
            r = []
            AssLauncher::Enterprise::Cli::CliSpec
              .cli_def.parameters.parameters.each do |p|
              if match?(p) && not_filtred?(p)
                r << p
                r << p.parent if p.parent && !r.include?(p.parent)
              end
            end
            r
          end

          def execute
            r = select_parameters.map do |p|
              Row.new(p)
            end
            r.sort_by { |row| row.param.full_name }
          end

          def max_col_width(col, rows)
            [rows.map do |r|
              r.send(col).to_s.length
            end.max, col.to_s.length].max
          end

          require 'io/console'
          def term_width(trim = 0)
            IO.console.winsize[1] - trim
          end

          def eval_width(col, total, r, trim, rows)
            [(term_width(trim) - r.values.inject(0) { |i, o| o + i }) / total,
             max_col_width(col, rows)].min
          end

          # rubocop:disable Style/ConditionalAssignment
          def columns_width(columns, rows)
            total = columns.size + 1
            columns.each_with_object({}) do |col, r|
              total -= 1
              if [:usage, :parameter, :dsl_method].include? col
                r[col] = max_col_width(col, rows)
              else
                r[col] = eval_width(col, total, r,
                                    4 + (columns.size - 1) * 3, rows)
              end
            end
          end

          def main_header
            if dev_mode
              r = 'DSL METHODS'
            else
              r = 'CLI PARAMETERS'
            end
            r << " AVAILABLE FOR: \"#{client}\" CLIENT V#{version}"
            r << " IN \"#{mode}\" RUNNING MODE" if client == :thick
            r.upcase
          end
          # rubocop:enable Style/ConditionalAssignment

          def filter_header
            "FILTERED BY: #{query}" if query
          end

          # rubocop:disable all
          # @doto: refactoring and tests require
          def to_table(columns)
            require 'command_line_reporter'
            extend CommandLineReporter

            header title: main_header, width: main_header.length, rule: true,
                   align: 'center', bold: true, spacing: 0

            header title: filter_header, width: filter_header.length, rule: true,
                   align: 'center', bold: false, color: 'yellow', spacing: 0 if\
                   filter_header

            grouped_rows.each do |gname, rows|
              next if rows.size.zero?
              table(border: true, encoding: :ascii) do
                header title: "PARAMTERS GROUP: \"#{groups[gname][:desc]}\"",
                  bold: true

                row header: true do
                  columns_width(columns, rows).each do |col, width|
                    column(col.upcase, width:  [width, 1].max)
                  end
                end
                rows.each do |row_|
                  row do
                    columns.each do |col|
                      column(row_.send(col))
                    end
                  end
                end
              end
            end
            nil
          end
          # rubocop:enable all

          def to_csv(columns)
            r = "#{columns.join(';')}\n"
            rows.each do |row|
              r << row.to_csv(columns)
              r << "\n"
            end
            r
          end
        end
        # rubocop:enable Metrics/ClassLength

        def self.command_name
          'cli-help'
        end

        def self._banner
          'show help for 1C:Enterprise CLI parameters'
        end

        def columns
          cols = dev_mode? ? Report::DEVEL_COLUMNS : Report::USAGE_COLUMNS
          cols -= [:parent, :parameter, :group, :require] unless verbose?
          cols
        end

        def formating(report)
          return report.to_table(columns) if format == :ascii
          report.to_csv(columns)
        end

        def execute
          $stdout.puts formating Report.new(client, mode, validate_version,
                                            show_appiared_only?, query,
                                            dev_mode?)
        end
      end

      # Mixin
      # @api private
      module ParseIbPath
        include AssLauncher::Api
        require 'uri'
        def connection_string
          case ib_path
          when %r{https?://}i then cs_http(ws: ib_path)
          when %r{tcp://}i then parse_tcp_path
          else cs_file(file: ib_path)
          end
        end

        def parse_tcp_path
          u = URI(ib_path)
          cs_srv(srvr: "#{u.host}:#{u.port}", ref: u.path.gsub(%r{^/}, ''))
        end
      end

      # Abstarct run command
      # @api private
      class Run < SubCommand
        include Option::Version
        include Option::DryRun
        include Option::SearchPath
        include Option::User
        include Option::Password
        include Option::Uc
        include Option::Raw
        include Option::Arch
        include BinaryWrapper
        include ParseIbPath

        def self.command_name
          'run'
        end

        def self._banner
          'run 1C:Enterprise'
        end

        def command_(&block)
          if client == :thin
            binary_wrapper.command((raw_param.flatten || []), &block)
          else
            binary_wrapper.command(mode, (raw_param.flatten || []), &block)
          end
        end

        # rubocop:disable Metrics/MethodLength
        def make_command
          usr = user
          pass = password
          uc_ = uc
          cs = connection_string
          cmd = command_ do
            connection_string cs
            _N usr if usr
            _P pass if pass
            _UC uc_ if uc_
          end
          cmd
        end
        # rubocop:enable Metrics/MethodLength

        def execute
          cmd = run_enterprise(make_command)
          puts Colorize.green(cmd.process_holder.result.assout) unless dry_run?
        end
      end
    end

    # @api private
    # Root of all subcommands
    class Main < Clamp::Command
      module SubCommands
        # show-version subcommand
        class ShowVersion < Abstract::SubCommand
          include AssLauncher::Enterprise::CliDefsLoader

          def self.command_name
            'show-version'
          end

          def self._banner
            'Show version of ass_launcher gem and'\
              ' list of known 1C:Enterprise'
          end

          def known_versions_list
            " - v#{defs_versions.reverse.map(&:to_s).join("\n - v")}"
          end

          def execute
            puts Colorize.yellow('ass_launcher:')\
              + Colorize.green(" v#{AssLauncher::VERSION}")
            puts Colorize.yellow('Known 1C:Enterprise:')
            puts Colorize.green(known_versions_list)
          end
        end

        # env subcommand
        class Env < Abstract::SubCommand
          include Abstract::Option::SearchPath
          include AssLauncher::Api

          def self.command_name
            'env'
          end

          def self._banner
            'Show 1C:Enterprise installations'
          end

          def list(clients)
            " - v#{clients.map do |cl|
              "#{cl.version} (#{cl.arch})"
            end.join("\n - v")}"
          end

          # rubocop:disable Metrics/AbcSize
          def execute
            puts Colorize.red "Ruby arch: #{RbConfig::CONFIG['arch']}"
            puts Colorize.yellow '1C:Enterprise installations was searching in:'
            puts Colorize
              .green " - #{AssLauncher::Enterprise.search_paths.join("\n - ")}"
            puts Colorize.yellow 'Thick client installations:'
            puts Colorize.green list(thicks.reverse)
            puts Colorize.yellow 'Thin client installations:'
            puts Colorize.green list(thins.reverse)
          end
          # rubocop:enable Metrics/AbcSize
        end
      end

      # Main cmd invoker
      Dir.glob File.join(File.expand_path('../cmd', __FILE__), '*.rb') do |lib|
        require lib if File.basename(lib) != 'abstract.rb'
      end

      extend Abstract::SubCommand::Declaration

      declare_subcommands
    end
  end
end
