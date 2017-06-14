#
module AssLauncher
  module Cmd
    module SubCommands
      class Web < Abstract::SubCommand
        def self.command_name
          'web'
        end

        def self._banner
          '1C:Enterprise Web client'
        end
      end
    end
  end
end
