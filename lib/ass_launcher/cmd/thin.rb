module AssLauncher
  module Cmd
    class Main
      module SubCommands
        # @api private
        class Thin < Abstract::SubCommand
          module SubCommands
            class Cli < Abstract::Cli; end
            # :nodoc:
            class Run < Abstract::Run
              include Abstract::Parameter::IB_PATH
            end
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
end
