require 'test_helper'
require 'ass_launcher/cmd'

module AssLauncher::Cmd
  module Test
    describe AssLauncher::Cmd::Main do
      def desc
        self.class.desc
      end

      def self.def_subcommand_test(cmd)
        it ".subcommands include? #{cmd}" do
          desc.recognised_subcommands
            .map {|sc| sc.subcommand_class.command_name}
            .must_include cmd.to_s.downcase
        end
      end

      def self.def_options_test(options)
        require 'pry'
        binding.pry
      end

      def_subcommand_test 'show-version'

      %i{Designer Thick Thin Web MakeIb}.each do |cmd|

        def_subcommand_test(cmd)

        describe cmd do
          define_method :desc do
            eval "AssLauncher::Cmd::SubCommands::#{cmd}"
          end

          %i{Cli Versions Run Uri}.each do |sub_cmd|

            if cmd == :MakeIb
              next
            end

            if sub_cmd == :Cli || sub_cmd == :Versions
              def_subcommand_test sub_cmd
            end

            if sub_cmd == :Run &&  cmd != :Web
              def_subcommand_test sub_cmd
            end

            if sub_cmd == :Uri && cmd == :Web
              def_subcommand_test sub_cmd
            end
          end
        end
      end
    end
  end
end
