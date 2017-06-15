#
module AssLauncher
  module Cmd
    module Main::SubCommands
      class Designer < Abstract::SubCommand
        module SubCommands
          class Cli < Abstract::Cli; end
        end
        def self.command_name
          'designer'
        end

        def self._banner
          '1C:Enterprise Thick client in DESIGNER mode'
        end

        declare_subcommands
      end
    end
  end
end
