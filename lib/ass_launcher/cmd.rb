require 'clamp'
module AssLauncher
  # AssLauncher command-line untils
  # @example
  #   $ass-launcher --help
  #
  module Cmd
    module Support
      module SrvStrParser
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
          invocation_path.split[-2]
        end

        def client
          case parrent_command
          when 'designer' then :thick
          when 'thick' then :thick
          when 'thin' then :thin
          when 'web'  then :web
          end
        end

        def mode
          case parrent_command
          when 'designer' then :designer
          when 'thick' then :enterprise
          when 'thin' then :enterprise
          when 'web'  then :webclient
          end
        end
      end

      module Option
        module SearchPath
          def self.included(base)
            base.option %w{--search-path -I}, 'PATH',
            'specify 1C:Enterprise installation path'
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
            base.option %w{--query -q}, 'REGEX', 'regular expression based filter' do |s|
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
            dbtypes = AssLauncher::Support::ConnectionString::DBMS_VALUES + ['File']

            define_method :valid_db_types do
              dbtypes
            end

            base.option '--dbms', 'DB_TYPE', "db type: #{dbtypes}.\nValue \"File\" for make file infobase", default: 'File' do |s|
              raise 'FIXME'
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
          def xml_dump?
            File.directory? pattern
          end

          def self.included(base)
            base.option %w{--pattern -P}, 'PATH', "pattern for make infobase\nPath to .cf, .dt files or xml-dump directory" do |s|
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
              pv =~ %r{^(\/|-)(\w+)+(.*)?}
              ["#{$1}#{$2}", $3.strip].select {|i| !i.empty?}
            end.flatten.map {|i| i.gsub('\\,', ',')}
          end

          def self.included(base)
            description =  "other 1C CLI parameters in raw(native) format.\n"\
              "Parameters and their arguments must be delimited comma-space sequence: `, '\n"\
              "If values includes comma comma must be slashed `\,'\n"\
              "WARNING: correctness of parsing will not guaranteed!"

            base.option '--raw', '"/Param VAL, -SubParam VAL"', description do |s|
              raw = parse_raw s
            end
          end
        end
      end

      module Parameter
        module IB_NAME
          def self.included(base)
            base.parameter 'IB_PATH', "path to infobase like a strings 'tcp://srv/ref' or 'http[s]://host/path' or 'path/to/ib'" do |s|
               raise 'FIXME'
            end
          end
        end

        module IB_PATH_NAME
          def self.included(base)
            base.parameter 'IB_PATH | IB_NAME', 'PATH for file or NAME for server infobase', attribute_name: :ib_path do |s|
              raise 'FIXME'
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
          'cli'
        end

        def self._banner
          'show help for 1C:Enterprise CLI parameters'
        end

        def execute
          Report.new(client, mode, version).execute($stdout, verbose?)
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
            'Show ass_launcher and known 1C:Enterprise versions'
          end

          def execute
            $stdout.puts "AssLauncher::VERSION: #{AssLauncher::VERSION}"
            $stdout.puts "Known 1C:Enterprise versions:"
            $stdout.puts " - #{defs_versions.map(&:to_s).join("\n - ")}"
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
