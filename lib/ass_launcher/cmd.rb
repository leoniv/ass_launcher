require 'clamp'
module AssLauncher
  # AssLauncher command-line untils
  # @example
  #   $ass-launcher --help
  #
  module Cmd
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
            base.option '--search-path', 'PATH',
            'specify 1C:Enterprise installation path'
          end
        end

        module AssVersion
          def self.included(base)
            base.option '--version', 'VERSION',
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
          def valid_dmbs
            AssLauncher::Support::ConnectionString::DBMS_VALUES
          end

          def self.included(base)
            dbms = AssLauncher::Support::ConnectionString::DBMS_VALUES.join(', ')
            base.option '--dbms', 'DB_SERVER_TYPE', "db server type: #{dbms}", required: true do |s|
              raise 'FIXME'
            end
          end
        end

        module Dbsrv
          def self.included(base)
            base.option '--dbsrv', 'user:pass@dbsrv', 'db server address', required: true do |s|
              raise 'FIXME'
            end
          end
        end

        module Esrv
          def self.included(base)
            base.option '--esrv', 'user:pass@esrv', 'enterprise server address', required: true do |s|
              raise 'FIXME'
            end
          end
        end
      end

      module Parameter
        module IB_NAME
          def self.included(base)
            base.parameter 'IB_PATH', "path to infoabse like a strings 'tcp://srv/ref' or 'http[s]://host/path' or 'path/to/ib'" do |s|
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
        include Option::AssVersion
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
