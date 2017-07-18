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
            include Abstract::Parameter::IB_PATH
            include Abstract::ParseIbPath
            include Abstract::ClientMode
            include AssLauncher::Api

            def self.command_name
              'uri'
            end

            def self._banner
              'Uri constructor for webclient'
            end

            def webclient
              cl = web_client(ib_path)
              cl.send(:add_to_query, cl.uri, cl.send(:args_to_query, raw_param.flatten))
              cl
            end

            def location
              user_ = user
              pass_ = password
              uc_   = uc
              raw_ = raw
              webclient.location do
                _N user_ if user_
                _P pass_ if pass_
              end
            end

            def execute
              Colorize.yellow location
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
