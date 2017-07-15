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
      Cli: ['cli', %r{show help for 1C:Enterprise CLI parameters}i],
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
      verbose: [%w[--verbose], :flag, %r{verbose}],
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
      esrv: [%w[--esrv], "user:pass@esrv", %r{enterprise server}]
    }

    OPTIONS_MATRIX = {
      ShowVersion: %i{},
      Env: %i{search_path},
      Designer: %i{},
      Thick: %i{},
      Thin: %i{},
      Web: %i{},
      MakeIb: %i{pattern dbms dbsrv esrv dry_run version search_path},
      Cli: %i{version verbose query},
      Uri: %i{user password uc raw},
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
            inst.query.must_equal %r{\s+}
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
            inst.parse_raw('/Param VALUE1\, VALUE2 VALUE3, -SubParam VALUE, /Param2')
              .must_equal  ['/Param', 'VALUE1, VALUE2 VALUE3', '-SubParam', "VALUE", '/Param2']
          end

          it '#run' do
            inst = cmd_class(desc).new('')
            inst.run ['--raw', '/P1 VALUE1', '--raw', '/P2 VALUE2']
            inst.raw_list.must_equal [['/P1', 'VALUE1'], ['/P2', 'VALUE2']]
            inst.raw_param.must_equal ['/P1', 'VALUE1', '/P2', 'VALUE2']
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
        cmd.expects(:version).returns(:version)
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

      it '#vrequrement default' do
        cmd.expects(:version).returns(nil)
        cmd.vrequrement.must_equal ''
      end

      it '#vrequrement' do
        cmd.expects(:version).returns(:version).twice
        cmd.vrequrement.must_equal '= version'
      end

      it '#run_enterise dry_run' do
        cmd.expects(:dry_run?).returns(true)
        command = stub to_s: 'command dryrun'
        AssLauncher::Cmd::Colorize.expects(:yellow)
          .with('command dryrun').returns('command dryrun')
        cmd.expects(:puts).with('command dryrun')
        cmd.run_enterise(command)
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
          cmd.expects(:version).twice.returns(v.to_s)
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
          cmd.expects(:version).twice.returns(v.to_s)
          wrapper = cmd.binary_wrapper
          wrapper.must_be_instance_of AssLauncher::Enterprise::BinaryWrapper::ThinClient
          wrapper.version.must_equal thins.first.version
        end
      end
    end

    describe AssLauncher::Cmd::Abstract::Run do
      def cmd
        @cmd ||= Class.new(self.class.desc) do
          def initialize

          end
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

    describe 'Examples' do

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
          out.must_match %r{1cv8(\.exe)? CREATEINFOBASE File='tmp\\fake.ib'}
          out.must_match %r{/UseTemplate .*/cmd_test\.rb}
          out.must_match %r{/DisableStartupDialogs  /DisableStartupMessages  /OUT \S+}
        end
      end
    end
  end
end
