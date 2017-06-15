require 'test_helper'
require 'ass_launcher/cmd'

module AssLauncher::Cmd
  module Test
    describe AssLauncher::Cmd::Main do
      def desc
        return self.class.desc unless self.class.desc.is_a? String
        eval(self.class.desc)
      end

      MAIN_SUBCOMMANDS = {
        ShowVersion: ['show-version', %r{Show ass_launcher and known 1C:Enterprise versions}],
        Designer: ['designer', %r{1C:Enterprise Thick client in DESIGNER mode}i],
        Thick: ['thick', %r{1C:Enterprise Thick client in ENTERPRISE mode}i],
        Thin: ['thin', %r{1C:Enterprise Thin client}i],
        Web: ['web', %r{1C:Enterprise Web client}i],
        MakeIb: ['makeib', %r{Make new information base}i]}

      NESTED_SUBCOMMANDS = {
        Cli: ['cli', %r{show help for 1C:Enterprise CLI parameters}i],
        Versions: ['versions', %r{FIXME}],
        Uri: ['uri', %r{FIXME}],
        Run: ['run', %r{FIXME}]}

      MAIN_NESTED_MATRIX = {
        ShowVersion: %i{},
        Designer: %i{Cli Versions Run},
        Thick: %i{Cli Versions Run},
        Thin: %i{Cli Versions Run},
        Web: %i{Cli Uri},
        MakeIb: %i{}
      }

      OPTIONS = {
        search_path: [%w[--search-path -I], 'PATH', %r{specify.+installation path}],
        version: [%w[--version -v], 'VERSION', %r{specify.+Enterprise version}],
        verbose: [%w[--verbose], :flag, %r{verbose}],
        query: [%w[--query -q], 'REGEX', %r{regular.+filter}],
#        infoabse: [%w[--infoabse, -i], 'IBPATH', %r{specify.+infoabse path}, {required: true}],
        user: [%w[--user -u], 'NAME', %r{infobase user name}],
        password: [%w[--password -p ], 'PASSWORD', %r{infoabse user password}],
        uc: [%w[--uc], 'LOCK_CODE', %r{infoabse lock code}],
        dry_run: [%w[--dry-run -n], :flag, %r{puts cmd string on stdout}],
        raw: [%w[--raw], "\"/Param VAL, -SubParam VAL\"", %r{raw paramteres string}],
        pattern: [%w[--pattern -p], 'PATH', %r{\.cf, \.dt files or xml-dump directory}],
        dbms: [%w[--dbms], "DB_SERVER_TYPE", %r{db server type}, {required: true}],
        dbsrv: [%w[--dbsrv], "user:pass@dbsrv", %r{db server}, {required: true}],
        esrv: [%w[--esrv], "user:pass@esrv", %r{enterprise server}, {required: true}]
      }

      OPTIONS_MATRIX = {
        ShowVersion: %i{},
        Designer: %i{},
        Thick: %i{},
        Thin: %i{},
        Web: %i{},
        MakeIb: %i{pattern dbms dbsrv esrv},
        Cli: %i{version verbose query},
        Versions: %i{search_path},
        Uri: %i{user password uc raw},
        Run: %i{search_path version user password uc dry_run raw}
      }

      PARAMTERS = {
        IB_PATH: ['IB_PATH', %r{path to information base}],
        IB_PATH_NAME: ['IB_PATH | IB_NAME',
                       %{PATH for file or NAME for server infobase}, :attribute_name => 'ib_path']
      }

      PARAMTERS_MATRIX = {
        ShowVersion: %i{},
        Designer: %i{},
        Thick: %i{},
        Thin: %i{},
        Web: %i{},
        MakeIb: %i{IB_PATH_NAME},
        Cli: %i{},
        Versions: %i{},
        Uri: %i{IB_PATH},
        Run: %i{IB_PATH}
      }

      def self.it_has_subcommand(klass, spec)
        it "has subcommand #{spec[0]}" do
          cmd = desc.find_subcommand(spec[0])
          cmd.wont_be_nil
          cmd.subcommand_class.must_equal eval("#{desc}::SubCommands::#{klass}")
          cmd.description.must_match spec[1]
        end
      end

      def self.it_subcommand_size(expected_subcommands)
        it "subcommand size" do
          desc.recognised_subcommands.size.must_equal expected_subcommands.size
        end
      end

      def self.it_has_option(option, spec)
        it "has option #{spec[0][0]}" do
          opt = desc.find_option spec[0][0]
          opt.wont_be_nil
          opt.switches.must_equal spec[0]
          opt.type.must_equal spec[1]
          opt.description.must_match spec[2]
          opt.required?.must_eqal (spec[3] || {})[:required]
        end
      end

      def self.it_has_parameter(param, spec)
        it "has parameters #{param}" do
          p = desc.parameters.find {|i| i.name == spec[0]}
          p.wont_be_nil
          p.description.must_match spec[1]
          p.attribute_name.must_equal (spec[2] || {})[:attribute_name]
        end
      end

      it_subcommand_size MAIN_SUBCOMMANDS

      MAIN_SUBCOMMANDS.each do |klass, spec|

        it_has_subcommand klass, spec

        describe "#{desc}::SubCommands::#{klass}" do

          it_subcommand_size MAIN_NESTED_MATRIX[klass]

          OPTIONS.select {|k, v| OPTIONS_MATRIX[klass].include? k}.each do |option, spec|
            it_has_option option, spec
          end

          PARAMTERS.select {|k,v| PARAMTERS_MATRIX[klass].include? k}.each do |param, spec|
            it_has_parameter param, spec
          end

          NESTED_SUBCOMMANDS.select {|k,v| MAIN_NESTED_MATRIX[klass].include? k}.each do |klass, spec|
            it_has_subcommand klass, spec

            describe "#{desc}::SubCommands::#{klass}" do
              OPTIONS.select {|k, v| OPTIONS_MATRIX[klass].include? k}.each do |option, spec|
                it_has_option option, spec
              end

              PARAMTERS.select {|k,v| PARAMTERS_MATRIX[klass].include? k}.each do |param, spec|
                it_has_parameter param, spec
              end
            end
          end
        end
      end

#      def_subcommands_test(MAIN_SUBCOMMANDS)
#
#      def_subcommand_test 'show-version'
#
#
#      MAIN_DECLARED_SUBCOMMANDS.each do |cmd|
#
#        def_subcommand_test(cmd)
#
#        describe "SubCommands::#{cmd}" do
#          define_method :desc do
#            eval "AssLauncher::Cmd::Main::SubCommands::#{cmd}"
#          end
#
#          %i{Cli Versions Run Uri}.each do |sub_cmd|
#
#            if cmd == :MakeIb
#              next
#            end
#
#            if sub_cmd == :Cli || sub_cmd == :Versions
#              def_subcommand_test sub_cmd
#            end
#
#            if sub_cmd == :Run &&  cmd != :Web
#              def_subcommand_test sub_cmd
#            end
#
#            if sub_cmd == :Uri && cmd == :Web
#              def_subcommand_test sub_cmd
#            end
#          end
#        end
#      end
    end
  end
end
