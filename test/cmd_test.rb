require 'test_helper'
require 'ass_launcher/cmd'

module AssLauncher::Cmd
  module Test

    MAIN_SUBCOMMANDS = {
      ShowVersion: ['show-version', %r{Show version of ass_launcher gem and list of known\s+1C:Enterprise}],
      Env: ['env', %r{Show 1C:Enterprise installations}],
      Designer: ['designer', %r{1C:Enterprise Thick client in DESIGNER mode}i],
      Thick: ['thick', %r{1C:Enterprise Thick client in ENTERPRISE mode}i],
      Thin: ['thin', %r{1C:Enterprise Thin client}i],
      Web: ['web', %r{1C:Enterprise Web client}i],
      MakeIb: ['makeib', %r{Make new information base}i]}

    NESTED_SUBCOMMANDS = {
      Cli: ['cli-help', %r{show help for 1C:Enterprise CLI parameters}i],
      Uri: ['uri', %r{Uri constructor for webclient}],
      Run: ['run', %r{run 1C:Enterprise}]}

    MAIN_NESTED_MATRIX = {
      ShowVersion: %i{},
      Env: %i{},
      Designer: %i{Cli Run},
      Thick: %i{Cli Run},
      Thin: %i{Cli Run},
      Web: %i{Cli Uri},
      MakeIb: %i{}
    }

    OPTIONS = {
      search_path: [%w[--search-path -I], 'PATH', %r{specify.+installation path}],
      version: [%w[--version -v], 'VERSION', %r{specify.+Enterprise version}],
      verbose: [%w[--verbose], :flag, %r{show more information}i],
      query: [%w[--query -q], 'REGEX', %r{regular.+filter}],
#        infobase: [%w[--infobase, -i], 'IBPATH', %r{specify.+infobase path}, {required: true}],
      user: [%w[--user -u], 'NAME', %r{infobase user name}],
      password: [%w[--password -p], 'PASSWORD', %r{infobase user password}],
      uc: [%w[--uc], 'LOCK_CODE', %r{infobase lock code}],
      dry_run: [%w[--dry-run], :flag, %r{puts cmd string}],
      raw: [%w[--raw], "\"/Par VAL, -SubPar VAL\"", %r{parameters in raw\(native\) format}, {multivalued: true}],
      pattern: [%w[--pattern -P], 'PATH', %r{\.cf, \.dt files}],
      dbms: [%w[--dbms], "DB_TYPE", %r{db type}, {default: 'File'}],
      dbsrv: [%w[--dbsrv], "user:pass@dbsrv", %r{db server}],
      esrv: [%w[--esrv], "user:pass@esrv", %r{enterprise server}],
      show_appiared_only: [%w[--show-appiared-only -a], :flag, %r{show parameters which appiared in --version only}],
      dev_mode: [%w[--dev-mode -d], :flag, %r{Show DSL methods}],
      format: [%w[--format -f], 'ascii|csv', %r{output format}, {default: :ascii}]
    }

    OPTIONS_MATRIX = {
      ShowVersion: %i{},
      Env: %i{search_path},
      Designer: %i{},
      Thick: %i{},
      Thin: %i{},
      Web: %i{},
      MakeIb: %i{pattern dbms dbsrv esrv dry_run version search_path},
      Cli: %i{version verbose query dev_mode show_appiared_only format},
      Uri: %i{user password raw},
      Run: %i{search_path version user password uc dry_run raw}
    }

    PARAMTERS = {
      IB_PATH: ['IB_PATH', %r{path to infobase},
                 :attribute_name => 'ib_path'],
      IB_PATH_NAME: ['IB_PATH | IB_NAME',
                     %{PATH for file or NAME for server infobase}, :attribute_name => 'ib_path']
    }

    PARAMTERS_MATRIX = {
      ShowVersion: %i{},
      Env: %i{},
      Designer: %i{},
      Thick: %i{},
      Thin: %i{},
      Web: %i{},
      MakeIb: %i{IB_PATH_NAME},
      Cli: %i{},
      Uri: %i{IB_PATH},
      Run: %i{IB_PATH}
    }

    module Support
      module CaptureStdout
        def capture_stdout(&block)
          original_stdout = $stdout
          $stdout = fake = StringIO.new
          begin
            yield
          ensure
            $stdout = original_stdout
          end
          fake.string
        end
      end
    end

    describe AssLauncher::Cmd::Main do
      def desc
        return self.class.desc unless self.class.desc.is_a? String
        eval(self.class.desc)
      end

      def self.it_has_subcommand(klass, spec)
        it "has subcommand #{spec[0]}" do
          cmd = desc.find_subcommand(spec[0])
          cmd.wont_be_nil "#{klass} #{spec[0]}"
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
          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--search-path', 'custom/path']
            begin
              AssLauncher.config.search_path.must_equal 'custom/path'
              inst.search_path.must_equal 'custom/path'
            ensure
              AssLauncher.config.search_path = nil
            end
          end
        end
        module Version
          extend Minitest::Spec::DSL
          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--version', '8.3.2.1']
            inst.version.must_equal Gem::Version.new('8.3.2.1')
          end
        end
        module Verbose
          extend Minitest::Spec::DSL
          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--verbose']
            inst.verbose?.must_equal true
          end
        end
        module Query
          extend Minitest::Spec::DSL
          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--query', '\s+']
            inst.query.must_equal %r{\s+}i
          end

          it '#run fail' do
            inst = cmd_class(desc).new('')
            e = proc {
              inst.run ['--query', '[']
            }.must_raise Clamp::UsageError
          end
        end
        module Dbms
          extend Minitest::Spec::DSL
          it '#run default' do
            inst = cmd_class(desc).new('')
            inst.run []
            inst.dbms.must_equal 'File'
          end

          it '#run fail' do
            inst = cmd_class(desc).new('')

            e = proc {
              inst.run ['--dbms', 'invalid']
            }.must_raise Clamp::UsageError
            e.message
              .must_match %r{\[MSSQLServer PostgreSQL IBMDB2 OracleDatabase File\]}i
          end

          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--dbms', 'PostgreSQL']
            inst.dbms.must_equal 'PostgreSQL'
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

          it '#run with file' do
            inst = cmd_class(desc).new('')
            inst.run ['--pattern', __FILE__]
            inst.pattern.must_equal __FILE__
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
            inst.parse_raw('/Param VALUE1\, VALUE2 VALUE3, -FlagParam, -SubParam \'/PATH1/PATH\' \'/PATH2/PATH\', /FlagParam')
              .must_equal  [['/Param', 'VALUE1, VALUE2 VALUE3'],
                            ['-FlagParam', ''],
                            ['-SubParam', '\'/PATH1/PATH\' \'/PATH2/PATH\''],
                            ['/FlagParam', '']]
          end

          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--raw', '/P1 VALUE1', '--raw', '/P2 VALUE2']
            inst.raw_list.must_equal [[['/P1', 'VALUE1']], [['/P2', 'VALUE2']]]
            inst.raw_param.must_equal [['/P1', 'VALUE1'], ['/P2', 'VALUE2']]
          end
        end
        module ShowAppiaredOnly
          extend Minitest::Spec::DSL
          it '#run with --show-appiared-only' do
            inst = cmd_class(desc).new('')
            inst.run ['--show-appiared-only']
            inst.show_appiared_only?.must_equal true
          end

          it '#run default' do
            inst = cmd_class(desc).new('')
            inst.run []
            inst.show_appiared_only?.must_be_nil
          end
        end
        module DevMode
          extend Minitest::Spec::DSL
          it '#run with --dev-mode' do
            inst = cmd_class(desc).new('')
            inst.run ['--dev-mode']
            inst.dev_mode?.must_equal true
          end

          it '#run default' do
            inst = cmd_class(desc).new('')
            inst.run []
            inst.dev_mode?.must_be_nil
          end
        end
        module Format
          extend Minitest::Spec::DSL
          it '#run default' do
            inst = cmd_class(desc).new('')
            inst.run []
            inst.format.must_equal :ascii
          end

          it '#run with --format' do
            inst = cmd_class(desc).new('')
            inst.run ['--format', 'csv']
            inst.format.must_equal :csv
          end

          it '#run fail' do
            inst = cmd_class(desc).new('')
            e = proc {
              inst.run ['--format', 'invalid']
            }.must_raise Clamp::UsageError
            e.message.must_match %r{Invalid format `invalid'}i
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
            if (spec[3] || {})[:multivalued]
              opt.default_value.must_equal []
            else
              opt.default_value.to_s.must_equal (spec[3] || {})[:default].to_s
            end
          end

          include OptionSpecs.const_get desc.to_sym
        end
      end
    end

    describe AssLauncher::Cmd::Abstract::BinaryWrapper do
      def cmd
        @cmd ||= Class.new(Clamp::Command) do
          def initialize; end
          include AssLauncher::Cmd::Abstract::BinaryWrapper
        end.new
      end

      it 'include? ClientMode' do
        cmd.class.include?(AssLauncher::Cmd::Abstract::ClientMode)
          .must_equal true
      end

      it 'include? AssLauncher::Api' do
        cmd.class.include?(AssLauncher::Api)
          .must_equal true
      end

      it '#binary_wrapper fail' do
        cmd.expects(:binary_get).returns(nil)
        cmd.expects(:vrequrement).returns(:vrequrement)
        cmd.expects(:client).returns(:client)
        e = proc {
          cmd.binary_wrapper
        }.must_raise Clamp::ExecutionError
        e.message.must_match %r{1C:Enterprise.+not installed}
      end

      it '#binary_wrapper' do
        cmd.expects(:binary_get).returns(:binary_wrapper)
        cmd.binary_wrapper.must_equal :binary_wrapper
      end

      it '#binary_get :thick' do
        cmd.expects(:client).returns(:thick)
        cmd.expects(:vrequrement).returns(:vrequrement)
        cmd.expects(:thicks).with(:vrequrement).returns([:wrapper])
        cmd.send(:binary_get).must_equal :wrapper
      end

      it '#binary_get :thin' do
        cmd.expects(:client).returns(:thin)
        cmd.expects(:vrequrement).returns(:vrequrement)
        cmd.expects(:thins).with(:vrequrement).returns([:wrapper])
        cmd.send(:binary_get).must_equal :wrapper
      end

      describe '#vrequrement' do
        it 'default' do
          cmd.expects(:version).returns(nil)
          cmd.vrequrement.must_equal ''
        end

        it 'version.sections equal 3 digits' do
          cmd.expects(:version).returns(Gem::Version.new('8.3.2')).at_least 1
          Gem::Requirement.new(cmd.vrequrement).to_s.must_equal '~> 8.3.2.0'
        end

        it 'version.sections equal 2 digits' do
          cmd.expects(:version).returns(Gem::Version.new('8.3')).at_least 1
          Gem::Requirement.new(cmd.vrequrement).to_s.must_equal '~> 8.3.0'
        end

        it 'version.sections more 3' do
          cmd.expects(:version).returns(Gem::Version.new('8.3.2.1')).at_least 1
          Gem::Requirement.new(cmd.vrequrement).to_s.must_equal '= 8.3.2.1'
        end

        it 'version.sections less 2' do
          cmd.expects(:version).returns(Gem::Version.new('8')).at_least 1
          Gem::Requirement.new(cmd.vrequrement).to_s.must_equal '= 8'
        end
      end

      it '#run_enterprise dry_run' do
        cmd.expects(:dry_run?).returns(true)
        cmd.expects(:dry_run).with(:command).returns('command dryrun')
        AssLauncher::Cmd::Colorize.expects(:yellow)
          .with('command dryrun').returns('command dryrun')
        cmd.expects(:puts).with('command dryrun')
        cmd.run_enterprise(:command)
      end

      it '#run_enterprise fail' do
        comand = mock
        comand.expects(:run).returns(comand)
        comand.expects(:wait).returns(comand)
        comand.expects(:result).returns(comand)
        comand.expects(:verify!)
          .raises(AssLauncher::Support::Shell::RunAssResult::RunAssError.new('assmessage'))
        comand.expects(:process_holder).returns(comand)
        comand.expects(:result).returns(comand)
        comand.expects(:exitstatus).returns(100)
        cmd.expects(:dry_run?).returns(false)

        e = proc {
          cmd.run_enterprise(comand)
        }.must_raise Clamp::ExecutionError
      end

      describe 'Test with real 1C' do
        include AssLauncher::Api
        before do
          skip '1C not found' if thicks.size == 0
        end

        it '#binary_wrapper :thick default version' do
          cmd.expects(:client).returns(:thick)
          cmd.expects(:version).returns(nil)
          wrapper = cmd.binary_wrapper
          wrapper.must_be_instance_of AssLauncher::Enterprise::BinaryWrapper::ThickClient
          wrapper.version.must_equal thicks.last.version
        end

        it '#binary_wrapper :thick specified version' do
          v = thicks.first.version
          cmd.expects(:client).returns(:thick)
          cmd.expects(:version).at_least(1).returns(v)
          wrapper = cmd.binary_wrapper
          wrapper.must_be_instance_of AssLauncher::Enterprise::BinaryWrapper::ThickClient
          wrapper.version.must_equal thicks.first.version
        end

        it '#binary_wrapper :thin default version' do
          cmd.expects(:client).returns(:thin)
          cmd.expects(:version).returns(nil)
          wrapper = cmd.binary_wrapper
          wrapper.must_be_instance_of AssLauncher::Enterprise::BinaryWrapper::ThinClient
          wrapper.version.must_equal thins.last.version
        end

        it '#binary_wrapper :thin specified version' do
          v = thins.first.version
          cmd.expects(:client).returns(:thin)
          cmd.expects(:version).at_least(1).returns(v)
          wrapper = cmd.binary_wrapper
          wrapper.must_be_instance_of AssLauncher::Enterprise::BinaryWrapper::ThinClient
          wrapper.version.must_equal thins.first.version
        end
      end
    end

    describe AssLauncher::Cmd::Abstract::Run do
      include Support::CaptureStdout

      [AssLauncher::Cmd::Main::SubCommands::Designer::SubCommands::Run,
       AssLauncher::Cmd::Main::SubCommands::Thick::SubCommands::Run,
       AssLauncher::Cmd::Main::SubCommands::Thin::SubCommands::Run,
      ].each do |klass|
        it "#{klass}.superclass == AssLauncher::Cmd::Abstract::Run" do
          klass.superclass
            .must_equal  AssLauncher::Cmd::Abstract::Run, klass.name
        end
      end

      def cmd
        @cmd ||= Class.new(self.class.desc) do
          def initialize

          end
        end.new
      end

      it 'include? ParseIbPath' do
        self.class.desc.include?(AssLauncher::Cmd::Abstract::ParseIbPath)
          .must_equal true
      end

      it '#execute' do
        command = mock
        command.expects(:process_holder).returns(command)
        command.expects(:result).returns(command)
        command.expects(:assout).returns(:assout)

        cmd.expects(:make_command).returns(command)
        cmd.expects(:run_enterprise).with(command).returns(command)
        AssLauncher::Cmd::Colorize.expects(:green).with(:assout).returns('assout')

        out = capture_stdout do
          cmd.execute
        end

        out.must_equal "assout\n"
      end

      describe 'Test with real 1C' do
        include AssLauncher::Api

        def cmd
          @cmd ||= Class.new(AssLauncher::Cmd::Abstract::Run) do
            def initialize

            end
          end.new
        end

        before do
          skip '1C not found' if thicks.size == 0
        end

        def make_command_test(client, mode)
          actual = cmd.make_command

          actual.args.pop # pop temp /UOT file name like a "H:/tmp/ass_out..."
          expected = [ (mode == 'designer' ? 'DESIGNER' : 'ENTERPRISE'),
            "/P1", "V1",
            "/P2", "V2",
            "/S", "host/ib",
            "/N", "user",
            "/P", "password",
            "/UC", "uc"]
          expected += ["/AppAutoCheckVersion-", ""] if cmd.binary_wrapper.version > Gem::Version.new('8.3.8.0')
          expected += ["/DisableStartupDialogs", "",
            "/DisableStartupMessages", "",
            "/OUT"]
          actual.args.must_equal expected
        end

        %w{thick-designer thick-enterprise thin}.each do |client|
          it "#make_command for #{client}" do
            client, mode = *client.split('-')
            cmd.expects(:client).returns(client.to_sym).at_least_once
            cmd.expects(:mode).returns(mode.to_sym).at_least_once if client == 'thick'
            cmd.expects(:user).returns('user').at_least_once
            cmd.expects(:password).returns('password').at_least_once
            cmd.expects(:uc).returns('uc').at_least_once
            cmd.expects(:raw_param).returns(['/P1', 'V1', '/P2', 'V2']).at_least_once
            cmd.expects(:ib_path).twice.returns('tcp://host/ib').at_least_once

            make_command_test(client, mode)
          end
        end
      end
    end

    describe AssLauncher::Cmd::Abstract::ParseIbPath do
      def cmd
        @cmd ||= Class.new() do
          include AssLauncher::Cmd::Abstract::ParseIbPath
        end.new
      end

      it 'file ib_path' do
        cmd.expects(:ib_path).twice.returns('path/to/ibase')
        cs = cmd.connection_string
        cs.file.must_equal 'path/to/ibase'
      end

      it 'tcp ib_path' do
        cmd.expects(:ib_path).twice.returns('tcp://host.name:43/ibase')
        cs = cmd.connection_string
        cs.srvr.must_equal 'host.name:43'
        cs.ref.must_equal 'ibase'
      end

      it 'https ib_path' do
        cmd.expects(:ib_path).twice.returns('https://host/ibase')
        cs = cmd.connection_string
        cs.ws.must_equal 'https://host/ibase'
      end

      it 'http ib_path' do
        cmd.expects(:ib_path).twice.returns('http://host/ibase')
        cs = cmd.connection_string
        cs.ws.must_equal 'http://host/ibase'
      end
    end

    describe AssLauncher::Cmd::Abstract::Cli do
      include Support::CaptureStdout

      def cmd
        @cmd ||= self.class.desc.new('ass-launcher designer cli-help')
      end

      it '#run format :ascii as default' do
        report = mock
        report.expects(:to_table).with(:columns).returns(:report)
        AssLauncher::Cmd::Abstract::Cli::Report.expects(:new)
          .with(:thick, :designer, Gem::Version.new('8.3.8'), true, %r{.+}i, true)
          .returns(report)
        cmd.expects(:columns).returns(:columns)
        out = capture_stdout do
          cmd.run(['--version', '8.3.8', '--verbose', '--query', '.+', '--dev-mode', '-a'])
        end
        out.must_equal :report.to_s + "\n"
      end

      it '#run format :csv' do
        report = mock
        report.expects(:to_csv).with(:columns).returns(:report)
        AssLauncher::Cmd::Abstract::Cli::Report.expects(:new)
          .with(:thick, :designer, Gem::Version.new('8.3.8'), true, %r{.+}i, true)
          .returns(report)
        cmd.expects(:columns).returns(:columns)
        out = capture_stdout do
          cmd.run(['--version', '8.3.8', '--verbose', '--format', 'csv', '--query', '.+', '--dev-mode', '-a'])

        end
        out.must_equal :report.to_s + "\n"
      end

      it '#run fail if invalid version' do
        e = proc {
          cmd.run(['--version', '1.2.3', '--verbose', '--query', '.+'])
        }.must_raise Clamp::UsageError
        e.message.must_match %r{Unknown 1C:Enterprise v1\.2\.3}i
      end

      it '#columns when --verbose --dev-mode' do
        cmd.parse ['--verbose', '--dev-mode']
        cmd.columns.must_equal [:parameter, :dsl_method, :accepted_values,
                                :parent, :param_klass, :group, :require, :desc]
      end

      it '#columns when --dev-mode' do
        cmd.parse ['--dev-mode']
        cmd.columns.must_equal [:dsl_method, :accepted_values,
                                :param_klass, :desc]
      end

      it '#columns when --verbose not dev_mode?' do
        cmd.parse ['--verbose']
        cmd.columns.must_equal [:usage, :argument, :parent, :group, :desc]
      end

      it '#columns when not dev_mode?' do
        cmd.parse []
        cmd.columns.must_equal [:usage, :argument, :desc]
      end
    end

    describe AssLauncher::Cmd::Abstract::Cli::Report do
      include Support::CaptureStdout
      def desc
        self.class.desc
      end

      it 'constants' do
        desc.const_get(:USAGE_COLUMNS)
          .must_equal [:usage, :argument, :parent, :group, :desc]

        desc.const_get(:DEVEL_COLUMNS)
          .must_equal [:parameter, :dsl_method, :accepted_values, :parent,
                       :param_klass, :group, :require, :desc]
      end

      it '#to_csv smoky test' do
        report = desc.new(:thick, :designer, Gem::Version.new('8.3.9'), true, %r{.*}i, true)
        report.to_csv(desc.const_get(:DEVEL_COLUMNS)).must_match %r{#{desc.const_get(:DEVEL_COLUMNS).join(';')}}
      end

      it '#to_table smoky test' do
        report = desc.new(:thick, :designer, Gem::Version.new('8.3.9'), nil, %r{.*}i, true)
        out = capture_stdout do
          report.to_table(desc.const_get(:DEVEL_COLUMNS))
        end
        out.must_match %r{DSL METHODS AVAILABLE FOR: "THICK" CLIENT V8\.3\.9 IN "DESIGNER" RUNING MODE}
      end
    end

    describe 'Examples' do
      include Support::CaptureStdout

      module IncludeBinaryWrapper
        extend Minitest::Spec::DSL

        def desc
          self.class.desc
        end

        it 'includes BinaryWrapper' do
          desc.include?(AssLauncher::Cmd::Abstract::BinaryWrapper)
            .must_equal true
        end
      end

      def colorize(str)
        ColorizedString[str]
      end

      describe AssLauncher::Cmd::Main::SubCommands::ShowVersion do
        include AssLauncher::Enterprise::CliDefsLoader

        def cmd
          @cmd ||= self.class.desc.new('ass-launcher show-version')
        end

        it '#known_versions_list' do
          cmd.known_versions_list
            .must_equal " - v#{defs_versions.reverse.map(&:to_s).join("\n - v")}"
        end

        it '#run' do
          cmd.expects(:known_versions_list).returns(" - version list")
          out = capture_stdout do
            cmd.run []
          end

          expected = ''
          expected << colorize('ass_launcher:').yellow
          expected << colorize(" v#{AssLauncher::VERSION}").green
          expected << "\n"
          expected << colorize('Known 1C:Enterprise:').yellow
          expected << "\n"
          expected << colorize(' - version list').green
          expected << "\n"

          out.must_equal expected
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::Env do

        def cmd
          @cmd ||= self.class.desc.new('ass-launcher env')
        end

        it 'include? AssLauncher::Api' do
          cmd.class.include?(AssLauncher::Api).must_equal true
        end

        it '#list' do
          clients = 3.times.map do |i|
            stub(version: i)
          end

          cmd.list(clients).must_equal " - v#{[2,1,0].join("\n - v")}"
        end

        it '#run' do
          cmd.expects(:thicks).returns(:thicks)
          cmd.expects(:thins).returns(:thins)
          cmd.expects(:list).with(:thicks).returns('thicks')
          cmd.expects(:list).with(:thins).returns('thins')

          out = capture_stdout do
            cmd.run ['--search-path', './tmp']
          end

          expected = ''
          expected << colorize('1C:Enterprise installations was searching in:').yellow
          expected << "\n"
          expected << colorize(" - #{AssLauncher::Enterprise.search_paths
            .join("\n - ")}").green
          expected << "\n"
          expected << colorize('Thick client installations:').yellow
          expected << "\n"
          expected << colorize('thicks').green
          expected << "\n"
          expected << colorize('Thin client installations:').yellow
          expected << "\n"
          expected << colorize('thins').green
          expected << "\n"

          out.must_equal expected
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::MakeIb do
        include IncludeBinaryWrapper
        include AssLauncher::Api

        def cmd
          @cmd ||= self.class.desc.new('ass-launcher makeib')
        end

        def desc
          self.class.desc
        end

        it '#client' do
          cmd.client.must_equal :thick
        end

        it '#mode' do
          cmd.mode.must_equal :createinfobase
        end

        it '#run for srv infobase' do
          skip '1C not found' if thicks.size == 0
          out = capture_stdout do
            cmd.run ['--dbms', 'MSSQLServer',
                     '--dbsrv', 'sa:sapass@DBHOST\SQLEXPRESS2005',
                     '--esrv', 'euser:epass@ehosr',
                     '--pattern', __FILE__,
                     '--dry-run', 'tmp_ib']
          end
          out.must_match %r{1cv8(\.exe)? CREATEINFOBASE Srvr='ehosr';Ref='tmp_ib';}
          out.must_match %r{DBMS='MSSQLServer';DBSrvr='DBHOST\\SQLEXPRESS2005';}
          out.must_match %r{DB='tmp_ib';DBUID='sa';DBPwd='sapass';CrSQLDB='Y';}
          out.must_match %r{SUsr='euser';SPwd='epass'; /UseTemplate .*/cmd_test\.rb}
          out.must_match %r{/DisableStartupDialogs  /DisableStartupMessages  /OUT \S+}
        end

        it '#run for file infobase' do
          skip '1C not found' if thicks.size == 0
          out = capture_stdout do
            cmd.run [ '--pattern', __FILE__,
                      '--dry-run', 'tmp/fake.ib']
          end
          out.must_match %r{1cv8(\.exe)? CREATEINFOBASE File='tmp(\\|/)fake.ib'}
          out.must_match %r{/UseTemplate .*/cmd_test\.rb}
          out.must_match %r{/DisableStartupDialogs  /DisableStartupMessages  /OUT \S+}
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::Designer::SubCommands::Run do
        include Support::CaptureStdout
        include AssLauncher::Api
        def cmd
          @cmd = self.class.desc.new('ass-launcher designer run')
        end

        it '#client' do
          cmd.client.must_equal :thick
        end

        it '#mode' do
          cmd.mode.must_equal :designer
        end

        it '#run' do
          skip '1C not found' if thicks.size == 0
          out = capture_stdout do
            cmd.run [ '--dry-run',
              '--user', 'user',
              '--password', 'secret',
              '--uc', 'uc-code',
              '--raw', '/P1 V1, /P2 V2',
              'tcp://host/ib']
          end

          out.must_match %r{1cv8(\.exe)? DESIGNER /P1 'V1' /P2 'V2' /S 'host/ib' /N 'user' /P 'secret' /UC 'uc-code'( /AppAutoCheckVersion-)? /DisableStartupDialogs  /DisableStartupMessages}i
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::Thick::SubCommands::Run do
        include Support::CaptureStdout
        include AssLauncher::Api
        def cmd
          @cmd = self.class.desc.new('ass-launcher thick run')
        end

        it '#client' do
          cmd.client.must_equal :thick
        end

        it '#mode' do
          cmd.mode.must_equal :enterprise
        end

        it '#run' do
          skip '1C not found' if thicks.size == 0
          out = capture_stdout do
            cmd.run [ '--dry-run',
              '--user', 'user',
              '--password', 'secret',
              '--uc', 'uc-code',
              '--raw', '/P1 V1, /P2 V2',
              'tcp://host/ib']
          end

          out.must_match %r{1cv8(\.exe)? ENTERPRISE /P1 'V1' /P2 'V2' /S 'host/ib' /N 'user' /P 'secret' /UC 'uc-code'( /AppAutoCheckVersion-)? /DisableStartupDialogs  /DisableStartupMessages}i
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::Thin::SubCommands::Run do
        include Support::CaptureStdout
        include AssLauncher::Api
        def cmd
          @cmd = self.class.desc.new('ass-launcher thin run')
        end

        it '#client' do
          cmd.client.must_equal :thin
        end

        it '#mode' do
          cmd.mode.must_equal :enterprise
        end

        it '#run' do
          skip '1C not found' if thicks.size == 0

          out = capture_stdout do
            cmd.run [ '--dry-run',
              '--user', 'user',
              '--password', 'secret',
              '--uc', 'uc-code',
              '--raw', '/P1 V1, /P2 V2',
              'tcp://host/ib']
          end

          out.must_match %r{1cv8c(\.exe)? ENTERPRISE /P1 'V1' /P2 'V2' /S 'host/ib' /N 'user' /P 'secret' /UC 'uc-code' /AppAutoCheckVersion-  /DisableStartupDialogs  /DisableStartupMessages}
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::Web::SubCommands::Uri do
        include Support::CaptureStdout

        def cmd
          @cmd ||= self.class.desc.new('ass-launcher web uri')
        end

        it 'include? ParseIbPath' do
          self.class.desc.include?(AssLauncher::Cmd::Abstract::ParseIbPath)
            .must_equal true
        end

        it '#client' do
          cmd.client.must_equal :web
        end

        it '#mode' do
          cmd.mode.must_equal :webclient
        end

        it '#execute' do
          out = capture_stdout do
            cmd.run ['--user', 'user',
                     '--password', 'pass',
                     '--raw', '/P1 V1, /P2 V2, /Flag',
                     'http://host/ib']
          end
          ColorizedString[out].uncolorize.must_equal "http://host/ib?P1=V1&P2=V2&Flag&DisableStartupMessages&N=user&P=pass\n"
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::Designer::SubCommands::Cli do
        include Support::CaptureStdout

        def cmd
          @cmd ||= self.class.desc.new('ass-launcher designer cli-help')
        end

        it '#execute' do
          out = capture_stdout do
            cmd.run ['-q', 'no_result_qery']
          end
          out.must_match %r{CLI PARAMETERS AVAILABLE FOR: "THICK" CLIENT V\d+\.\d+\.\d+ IN "DESIGNER" RUNING MODE}
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::Web::SubCommands::Cli do
        include Support::CaptureStdout

        def cmd
          @cmd ||= self.class.desc.new('ass-launcher web cli-help')
        end

        it '#execute' do
          out = capture_stdout do
            cmd.run ['-q', 'no_result_qery']
          end
          out.must_match %r{CLI PARAMETERS AVAILABLE FOR: "WEB" CLIENT V\d+\.\d+\.\d+}
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::Thick::SubCommands::Cli do
        include Support::CaptureStdout

        def cmd
          @cmd ||= self.class.desc.new('ass-launcher thick cli-help')
        end

        it '#execute' do
          out = capture_stdout do
            cmd.run ['-q', 'no_result_qery']
          end
          out.must_match %r{CLI PARAMETERS AVAILABLE FOR: "THICK" CLIENT V\d+\.\d+\.\d+ IN "ENTERPRISE" RUNING MODE}
        end
      end

      describe AssLauncher::Cmd::Main::SubCommands::Thin::SubCommands::Cli do
        include Support::CaptureStdout

        def cmd
          @cmd ||= self.class.desc.new('ass-launcher thin cli-help')
        end

        it '#execute' do
          out = capture_stdout do
            cmd.run ['-q', 'no_result_qery']
          end
          out.must_match %r{CLI PARAMETERS AVAILABLE FOR: "THIN" CLIENT V\d+\.\d+\.\d+}
        end
      end
    end
  end
end
