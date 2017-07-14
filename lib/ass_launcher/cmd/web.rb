#
module AssLauncher
  module Cmd
    module Main::SubCommands
      class Web < Abstract::SubCommand
        module SubCommands
          class Cli < Abstract::Cli; end
          class Uri < Abstract::SubCommand
            include Abstract::Option::User
            include Abstract::Option::Password
            include Abstract::Option::Raw
            include Abstract::Option::Uc
            include Abstract::Parameter::IB_PATH

            def self.command_name
              'uri'
            end

            def self._banner
              'Uri constructor for webclient'
            end
          end
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
