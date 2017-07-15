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

      def self.method_missing(m, s)
        colorized(s).send(m)
      end

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
          return [host, nil, nil] if split.size == 0

          split = split[0].split(':')
          fail ArgumentError if split.size > 2

          user = split.shift
          pass = split.shift

          [host, user, pass]
        end
      end
    end

    # @api private
    # Abstract things
    module Abstract
      class SubCommand < Clamp::Command
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

        def self.command_name
          fail 'Abstract'
        end

        def self._banner
          fail 'Abstract'
        end
      end

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

      # @api private
      module BinaryWrapper
        include AssLauncher::Api
        include ClientMode

        def binary_wrapper
          binary_get ||\
            (fail "1C:Enterprise #{client} v#{version} not installed")
        end

        def vrequrement
          return "= #{version}" if version
          ''
        end

        def binary_get
          case client
          when :thick then thicks(vrequrement).last
          when :thin then thins(vrequrement).last
          end
        end
        private :binary_get

        def run_enterise(cmd)
          if respond_to?(:dry_run?) && dry_run?
            puts Colorize.yellow(cmd.to_s)
          else
            cmd.run.wait.result.verify!
          end
          cmd
        end
      end

      # @api private
      # All +Clamp::Command+ option mixins
      module Option
        module SearchPath
          def self.included(base)
            base.option %w{--search-path -I}, 'PATH',
            'specify 1C:Enterprise installation path' do |s|
              AssLauncher.config.search_path = s
              s
            end
          end
        end

        module Version
          def self.included(base)
            base.option %w{--version -v}, 'VERSION',
              'specify 1C:Enterprise version' do |s|
              version = Gem::Version.new(s)
            end
          end
        end

        module Verbose
          def self.included(base)
            base.option '--verbose', :flag, 'bee verbose'
          end
        end

        module Query
          def self.included(base)
            base.option %w{--query -q}, 'REGEX',
              'regular expression based filter' do |s|
              begin
                query = Regexp.new(s)
              rescue RegexpError => e
                fail ArgumentError, e.message
              end
            end
          end
        end

        module Dbms
          def self.included(base)
            dbtypes = AssLauncher::Support::ConnectionString::DBMS_VALUES\
              + ['File']

            define_method :valid_db_types do
              dbtypes
            end

            base.option '--dbms', 'DB_TYPE',
              "db type: #{dbtypes}.\nValue \"File\" for make file infobase",
              default: 'File' do |s|
              raise ArgumentError,
                "valid values: [#{valid_db_types.join(' ')}]" unless\
                valid_db_types.include? s
              s
            end
          end
        end

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

        module Esrv
          attr_reader :esrv_user, :esrv_pass, :esrv_host
          include Support::SrvStrParser
          def parse_esrv(s)
            @esrv_host, @esrv_user, @esrv_pass = parse_srv_str(s)
          end

          def self.included(base)
            base.option '--esrv', 'user:pass@esrv', 'enterprise server address' do |s|
              parse_esrv(s)
              s
            end
          end
        end

        module User
          def self.included(base)
            base.option %w{--user -u}, 'NAME', 'infobase user name'
          end
        end

        module Password
          def self.included(base)
            base.option %w{--password -p}, 'PASSWORD', 'infobase user password'
          end
        end

        module Pattern
          def self.included(base)
            base.option %w{--pattern -P}, 'PATH',
              "Template for make infobase. Path to .cf, .dt files" do |s|
              fail ArgumentError, "Path not exist: #{s}" unless File.exist?(s)
              s
            end
          end
        end

        module Uc
          def self.included(base)
            base.option '--uc', 'LOCK_CODE', 'infobase lock code'
          end
        end

        module DryRun
          def self.included(base)
            base.option %w{--dry-run}, :flag, 'will not realy run 1C:Enterprise only puts cmd string'
          end
        end

        module Raw
          def parse_raw(s)
            split = s.split(%r{(?<!\\),\s}).map(&:strip)

            split.map do |pv|
              fail ArgumentError, "Parse error in: #{pv}" unless pv =~ %r{^(/|-)}
              pv =~ %r{^(\/|-)([^\s]+)+(.*)?}
              ["#{$1}#{$2}", $3.strip].select {|i| !i.empty?}
            end.flatten.map {|i| i.gsub('\\,', ',')}
          end

          def raw_param
            raw_list.flatten
          end

          def self.included(base)
            description =  "other 1C CLI parameters in raw(native) format.\n"\
              "Parameters and their arguments must be delimited comma-space sequence: `, '\n"\
              "If values includes comma comma must be slashed `\\\\,'\n"\
              "WARNING: correctness of parsing will not guaranteed!"

            base.option '--raw', '"/Par VAL, -SubPar VAL"', description,
              multivalued: true do |s|
              raw = parse_raw s
            end
          end
        end
      end

      module Parameter
        module IB_PATH
          def self.included(base)
            base.parameter 'IB_PATH',
              "path to infobase like a strings"\
              " 'tcp://srv/ref' or 'http[s]://host/path' or 'path/to/ib'",
              attribute_name: :ib_path do |s|
               s
            end
          end
        end

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

      class Cli < SubCommand
        include Option::Version
        include Option::Verbose
        include Option::Query
        include ClientMode

        class Report
          attr_reader :client, :mode, :version
          def initialize(client, mode, version)
            @client = client
            @mode = mode
            @version = version
          end

          def header
            "1C:Enterprise-#{version} CLI parameters for #{client}-#{mode}:"
          end

          def execute(io, verbose = false)
            io.puts header
            raise 'FIXME'
          end
        end

        def self.command_name
          'cli-help'
        end

        def self._banner
          'show help for 1C:Enterprise CLI parameters'
        end

        def execute
          Report.new(client, mode, version).execute($stdout, verbose?)
        end
      end

      class Run < SubCommand
        require 'uri'
        include Option::Version
        include Option::DryRun
        include Option::SearchPath
        include Option::User
        include Option::Password
        include Option::Uc
        include Option::Raw
        include BinaryWrapper

        def self.command_name
          'run'
        end

        def self._banner
          "run 1C:Enterprise"
        end

        def parse_tcp_path
          u = URI(ib_path)
          cs_srv(srvr: "#{u.host}:#{u.port}", ref: u.path.gsub(%r{^/}, ''))
        end

        def connection_string
          case ib_path
          when %r{https?://}i then return cs_http(ws: ib_path)
          when %r{tcp://}i then return parse_tcp_path
          else return cs_file(file: ib_path)
          end
        end

        def command_(&block)
          if client == :thin
            binary_wrapper.command((raw_param || []), &block)
          else
            binary_wrapper.command(mode,(raw_param || []) ,&block)
          end
        end

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
            _AppAutoCheckVersion :-
          end
          cmd
        end

        def execute
          cmd = run_enterise(make_command)
          puts Colorize.green(cmd.process_holder.result.assout) unless dry_run?
        end
      end
    end

    class Main < Clamp::Command
      module SubCommands
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
            puts Colorize.yellow("ass_launcher:")\
              + Colorize.green(" v#{AssLauncher::VERSION}")
            puts Colorize.yellow("Known 1C:Enterprise:")
            puts Colorize.green(known_versions_list)
          end
        end

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
            " - v#{clients.map {|c| c.version}.sort.reverse.join("\n - v")}"
          end

          def execute
            puts Colorize.yellow "1C:Enterprise installations was searching in:"
            puts Colorize
              .green " - #{AssLauncher::Enterprise.search_paths.join("\n - ")}"
            puts Colorize.yellow "Thick client installations:"
            puts Colorize.green list(thicks)
            puts Colorize.yellow "Thin client installations:"
            puts Colorize.green list(thins)
          end
        end
      end

      # Main cmd invoker
      Dir.glob File.join(File.expand_path('../cmd',__FILE__),'*.rb') do |lib|
        require lib if File.basename(lib) != 'abstract.rb'
      end

      extend Abstract::SubCommand::Declaration

      declare_subcommands
    end
  end
end
