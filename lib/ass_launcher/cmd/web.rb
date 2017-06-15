#
module AssLauncher
  module Cmd
    module Main::SubCommands
      class Web < Abstract::SubCommand
        module SubCommands
          class Cli < Abstract::Cli; end
        end

        def self.command_name
          'web'
        end

        def self._banner
          '1C:Enterprise Web client'
        end

        declare_subcommands
      end
    end
  end
end
