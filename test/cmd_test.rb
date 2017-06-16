require 'test_helper'
require 'ass_launcher/cmd'

module AssLauncher::Cmd
  module Test

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
#        infobase: [%w[--infobase, -i], 'IBPATH', %r{specify.+infobase path}, {required: true}],
      user: [%w[--user -u], 'NAME', %r{infobase user name}],
      password: [%w[--password -p], 'PASSWORD', %r{infobase user password}],
      uc: [%w[--uc], 'LOCK_CODE', %r{infobase lock code}],
      dry_run: [%w[--dry-run], :flag, %r{puts cmd string}],
      raw: [%w[--raw], "\"/Param VAL, -SubParam VAL\"", %r{parameters in raw\(native\) format}],
      pattern: [%w[--pattern -P], 'PATH', %r{\.cf, \.dt files or xml-dump directory}],
      dbms: [%w[--dbms], "DB_TYPE", %r{db type}, {default: 'File'}],
      dbsrv: [%w[--dbsrv], "user:pass@dbsrv", %r{db server}],
      esrv: [%w[--esrv], "user:pass@esrv", %r{enterprise server}]
    }

    OPTIONS_MATRIX = {
      ShowVersion: %i{},
      Designer: %i{},
      Thick: %i{},
      Thin: %i{},
      Web: %i{},
      MakeIb: %i{pattern dbms dbsrv esrv dry_run},
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

    describe AssLauncher::Cmd::Main do
      def desc
        return self.class.desc unless self.class.desc.is_a? String
        eval(self.class.desc)
      end

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
    end

    describe AssLauncher::Cmd::Abstract::Option do
      def self.camelize(s)
        s.to_s.split('_').collect(&:capitalize).join
      end

      def camelize(s)
        self.class.camelize s
      end

      def cmd_class(option)
        Class.new(Clamp::Command) do
          include option

          def execute
            # NOP
          end
        end
      end

      module OptionSpecs
        module SearchPath
          extend Minitest::Spec::DSL
          it 'FIXME' do
            inst = cmd_class(desc).new('')
            raise 'FIXME'
          end
        end
        module Version
          extend Minitest::Spec::DSL
          it 'FIXME' do
            inst = cmd_class(desc).new('')
            raise 'FIXME'
          end
        end
        module Verbose
          extend Minitest::Spec::DSL
          it 'FIXME' do
            inst = cmd_class(desc).new('')
            raise 'FIXME'
          end
        end
        module Query
          extend Minitest::Spec::DSL
          it 'FIXME' do
            inst = cmd_class(desc).new('')
            raise 'FIXME'
          end
        end
        module Dbms
          extend Minitest::Spec::DSL
          it 'FIXME' do
            inst = cmd_class(desc).new('')
            raise 'FIXME'
          end
        end
        module Dbsrv
          extend Minitest::Spec::DSL
          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--dbsrv', 'user:pass@host:2020']
            inst.dbsrv_user.must_equal 'user'
            inst.dbsrv_pass.must_equal 'pass'
            inst.dbsrv_host.must_equal 'host:2020'
            inst.dbsrv.must_equal 'user:pass@host:2020'
          end

          it '#parse_dbsrv user@host:port' do
            inst = cmd_class(desc).new('')
            inst.parse_dbsrv 'user@host:port'
            inst.dbsrv_user.must_equal 'user'
            inst.dbsrv_pass.must_be_nil
            inst.dbsrv_host.must_equal 'host:port'
          end

          it '#parse_dbsrv host:port' do
            inst = cmd_class(desc).new('')
            inst.parse_dbsrv 'host:port'
            inst.dbsrv_user.must_be_nil
            inst.dbsrv_pass.must_be_nil
            inst.dbsrv_host.must_equal 'host:port'
          end
        end
        module Esrv
          extend Minitest::Spec::DSL
          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--esrv', 'user:pass@host:2020']
            inst.esrv_user.must_equal 'user'
            inst.esrv_pass.must_equal 'pass'
            inst.esrv_host.must_equal 'host:2020'
            inst.esrv.must_equal 'user:pass@host:2020'
          end

          it '#parse_esrv user@host:port' do
            inst = cmd_class(desc).new('')
            inst.parse_esrv 'user@host:port'
            inst.esrv_user.must_equal 'user'
            inst.esrv_pass.must_be_nil
            inst.esrv_host.must_equal 'host:port'
          end

          it '#parse_esrv host:port' do
            inst = cmd_class(desc).new('')
            inst.parse_esrv 'host:port'
            inst.esrv_user.must_be_nil
            inst.esrv_pass.must_be_nil
            inst.esrv_host.must_equal 'host:port'
          end
        end
        module User
          extend Minitest::Spec::DSL
          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--user', 'user']
            inst.user.must_equal 'user'
          end
        end
        module Password
          extend Minitest::Spec::DSL
          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--password', 'password']
            inst.password.must_equal 'password'
          end
        end
        module Pattern
          extend Minitest::Spec::DSL
          it '#run fail' do
            inst = cmd_class(desc).new('')
            e = proc {
              inst.run ['--pattern', '/notexists']
            }.must_raise Clamp::UsageError
            e.message.must_match %r{: /notexists}
          end

          it '#run with directory' do
            inst = cmd_class(desc).new('')
            inst.run ['--pattern', '.']
            inst.pattern.must_equal '.'
            inst.xml_dump?.must_equal true
          end

          it '#run with file' do
            inst = cmd_class(desc).new('')
            inst.run ['--pattern', __FILE__]
            inst.pattern.must_equal __FILE__
            inst.xml_dump?.must_equal false
          end
        end
        module Uc
          extend Minitest::Spec::DSL
          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--uc', 'uc val']
            inst.uc.must_equal 'uc val'
          end
        end
        module DryRun
          extend Minitest::Spec::DSL
          it '#run with --dry-run' do
            inst = cmd_class(desc).new('')
            inst.run ['--dry-run']
            inst.dry_run?.must_equal true
          end

          it '#run default' do
            inst = cmd_class(desc).new('')
            inst.run []
            inst.dry_run?.must_be_nil
          end
        end
        module Raw
          extend Minitest::Spec::DSL
          it "#parse_raw" do
            inst = cmd_class(desc).new('')
            inst.parse_raw('/Param VALUE1\, VALUE2 VALUE3, -SubParam VALUE, /Param2')
              .must_equal  ['/Param', 'VALUE1, VALUE2 VALUE3', '-SubParam', "VALUE", '/Param2']
          end

          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--raw', '/Param VALUE']
            inst.raw.must_equal ['/Param', 'VALUE']
          end
        end
      end

      OPTIONS.each do |name, spec|
        describe "#{camelize(name)}" do

          def desc
            AssLauncher::Cmd::Abstract::Option.const_get self.class.desc.to_sym
          end

          it "spec for #{spec[0][0]}" do
            desc.wont_be_nil
            desc.class.must_equal Module

            opt = cmd_class(desc).find_option spec[0][0]
            opt.wont_be_nil
            opt.switches.must_equal spec[0]
            opt.type.must_equal spec[1]
            opt.description.must_match spec[2]
            opt.required?.to_s.must_equal (spec[3] || {})[:required].to_s
            opt.default_value.to_s.must_equal (spec[3] || {})[:default].to_s
          end

          include OptionSpecs.const_get desc.to_sym
        end
      end
    end
  end
end
