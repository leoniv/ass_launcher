#
module AssLauncher
  module Cmd
    module SubCommands
      class Thick < Abstract::SubCommand
        class Cli < Abstract::Cli; end

        def self.command_name
          'thick'
        end

        def self._banner
          '1C:Enterprise Thick client in ENTERPRISE mode'
        end

        subcommand_ Cli
      end
    end
  end
end
