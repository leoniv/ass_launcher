#
module AssLauncher
  module Cmd
    module Main::SubCommands
      class MakeIb < Abstract::SubCommand
        include Abstract::Parameter::IB_PATH_NAME
        include Abstract::Option::Dbms
        include Abstract::Option::Dbsrv
        include Abstract::Option::Esrv
        include Abstract::Option::Pattern
        include Abstract::Option::Version
        include Abstract::Option::DryRun
        include Abstract::BinaryWrapper

        def self.command_name
          'makeib'
        end

        def self._banner
          'Make new information base'
        end

        def execute
          require 'pry'
          binding.pry
          raise 'FIXME'
        end
      end
    end
  end
end
