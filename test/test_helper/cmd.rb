require_relative './cli_def_report'
module TestHelper
  module Cmd
    class Main < Clamp::Command
        subcommand 'cli-def-report',
          'generate, csv formatted, report on defined CLI parameters'\
          ' and puts it into STDOUT. (see TestHelper::CliDefReport)',
          CliDefReport::Cmd::Report
    end
  end
end
