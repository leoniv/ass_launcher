module TestHelper
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
    require_relative './cli_def_report'
    require_relative './cli_def_snippets'
    require_relative './designer'

    class Main < Clamp::Command
        subcommand 'cli-def-report',
          'generate, csv formatted, report on defined CLI parameters'\
          ' and puts it into STDOUT. (see TestHelper::CliDefReport)',
          CliDefReport::Cmd::Report
        subcommand 'cli-def-snippets',
          CliDefSnippets::Cmd::Main._banner,
          CliDefSnippets::Cmd::Main
        subcommand 'designer', Designer::Cmd::Main.banner,
          Designer::Cmd::Main
    end
  end

end
