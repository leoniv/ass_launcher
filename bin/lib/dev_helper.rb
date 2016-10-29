module DevHelper
  module CliDefValidator
    require 'ass_launcher'
    def valid_clients
      AssLauncher::Enterprise::Cli::BinaryMatcher::ALL_CLIENTS
    end

    def valid_modes
      AssLauncher::Enterprise::Cli::DEFINED_MODES
    end

    def validate_clients
      fail ArgumentError,
        "Invalid clients. Expected #{valid_clients.map(&:to_s)}" if\
        (clients - valid_clients).size > 0
    end

    def validate_modes
      fail ArgumentError,
        "Invalid modes. Expected #{valid_modes.map(&:to_s)}" if\
        (modes - valid_modes).size > 0
    end

    def valid_groups
      AssLauncher::Enterprise::Cli::CliSpec.cli_def.parameters_groups.keys
    end

    def validate_group
      fail ArgumentError,
        "Invalid group `#{group_name}'."\
        " Expected #{valid_groups.map(&:to_s)}" unless\
          valid_groups.include?(group_name)
    end
  end

  module Cmd
    require_relative './dev_helper/cli_def_report'
    require_relative './dev_helper/cli_def_snippets'
    require_relative './dev_helper/designer'

    class Main < Clamp::Command

      subcommand 'show-version', 'show ass_launcher version' do
        def execute
          $stdout.puts AssLauncher::VERSION
        end
      end
      subcommand 'cli-def-report',
        'generate, csv formatted, report on defined CLI parameters'\
        ' and puts it into STDOUT. (see DevHelper::CliDefReport)',
        CliDefReport::Cmd::Report
      subcommand 'cli-def-snippets',
        CliDefSnippets::Cmd::Main._banner,
        CliDefSnippets::Cmd::Main
      subcommand 'designer', Designer::Cmd::Main.banner,
        Designer::Cmd::Main
    end
  end
end
