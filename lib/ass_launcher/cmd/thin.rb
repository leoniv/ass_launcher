#
module AssLauncher
  module Cmd
    module SubCommands
      class Thin < Abstract::SubCommand
        def self.command_name
          'thin'
        end

        def self._banner
          '1C:Enterprise Thin client'
        end
      end
    end
  end
end
