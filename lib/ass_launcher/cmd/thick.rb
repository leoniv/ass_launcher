#
module AssLauncher
  module Cmd
    module Main::SubCommands
      class Thick < Abstract::SubCommand
        module SubCommands
          class Cli < Abstract::Cli; end
          class Run < Abstract::Run
            include Abstract::Parameter::IB_PATH

          end
        end

        def self.command_name
          'thick'
        end

        def self._banner
          '1C:Enterprise Thick client in ENTERPRISE mode'
        end

        declare_subcommands
      end
    end
  end
end
