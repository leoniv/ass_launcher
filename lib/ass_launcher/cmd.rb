require 'clamp'
module AssLauncher
  # AssLauncher command-line untils
  # @example
  #   $ass-launcher --help
  #
  module Cmd
    module Abstract
      class SubCommand < Clamp::Command
        def self.subcommand_(klass)
          subcommand(klass.command_name, klass._banner, klass)
        end

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
          when 'thin' then nil
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
      end

      class Cli < SubCommand
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
        include Option::AssVersion
        include ClientMode

        def self.command_name
          'cli'
        end

        def self._banner
          'show help for 1C:Enterprise CLI parameters'
        end

        option '--verbose', :flag, 'bee verbose'
        option '--query', 'REGEX', 'regular expression based filter' do |s|
          begin
            query = Regexp.new(s)
          rescue RegexpError => e
            fail ArgumentError, e.message
          end
        end

        def execute
          Report.new(client, mode, version).execute($stdout, verbose?)
        end
      end
    end

    # Main cmd invoker
    Dir.glob File.join(File.expand_path('../cmd',__FILE__),'*.rb') do |lib|
      require lib if File.basename(lib) != 'abstract.rb'
    end

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

    class Main < Clamp::Command
      SubCommands.constants.each do |c|
        klass = SubCommands.const_get(c)
        subcommand(klass.command_name, klass._banner, klass) if\
          klass.superclass == Abstract::SubCommand
      end
    end
  end
end
