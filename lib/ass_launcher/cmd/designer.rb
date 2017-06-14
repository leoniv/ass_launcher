#
module AssLauncher
  module Cmd
    module SubCommands
      class Designer < Abstract::SubCommand
        def self.command_name
          'designer'
        end

        def self._banner
          '1C:Enterprise Thick client in DESIGNER mode'
        end
      end
    end
  end
end
