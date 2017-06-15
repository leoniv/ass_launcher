#
module AssLauncher
  module Cmd
    module Main::SubCommands
      class Thin < Abstract::SubCommand
        module SubCommands
          class Cli < Abstract::Cli; end
        end

        def self.command_name
          'thin'
        end

        def self._banner
          '1C:Enterprise Thin client'
        end

        declare_subcommands
      end
    end
  end
end
