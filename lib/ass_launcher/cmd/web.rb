module AssLauncher
  module Cmd
    class Main
      module SubCommands
        # @api private
        class Web < Abstract::SubCommand
          module SubCommands
            class Cli < Abstract::Cli; end
            # :nodoc:
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
                cl.send(:add_to_query, cl.uri,
                        cl.send(:args_to_query, raw_param.flatten))
                cl
              end

              def location
                user_ = user
                pass_ = password
                webclient.location do
                  _N user_ if user_
                  _P pass_ if pass_
                end.to_s
              end

              def execute
                puts Colorize.yellow location.to_s
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
end
