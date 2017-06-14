#
module AssLauncher
  module Cmd
    module SubCommands
      class MakeIb < Abstract::SubCommand
        def self.command_name
          'makeib'
        end

        def self._banner
          'Make new information base'
        end
      end
    end
  end
end
