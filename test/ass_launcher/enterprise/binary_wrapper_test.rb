# encoding: utf-8
require 'test_helper'

class BinaryWrapperTest < Minitest::Test

  def cls
    AssLauncher::Enterprise::BinaryWrapper
  end

  def inst_
    Class.new(cls) do
      def initialize

      end
      public :build_args
    end.new
  end

  def test_version
    path = mock
    path.expects(:to_s).returns(:path)
    inst = inst_
    inst.expects(:path).returns(path)
    inst.expects(:extract_version).with(:path).returns(:version)
    assert_equal :version, inst.version, 'expects call :extract_version'
    assert_equal :version, inst.version, 'return @version value'
  end

  def test_platform
    assert cls.include? AssLauncher::Support::Platforms
  end

  def test_extract_version_in_windows
    inst = inst_
    inst.expects(:linux?).returns(false)
    inst.expects(:v8).with('1.2.3.4').returns('1.2.3.4')
    assert_equal Gem::Version.new('1.2.3.4'),
      inst.send(:extract_version, 'bla/bla/1cv8/1.2.3.4/bin/1cv8.exe')
  end

  def test_extract_version_in_linux
    inst = inst_
    inst.expects(:linux?).returns(true)
    AssLauncher::Support::Linux.expects(:get_pkg_version)\
      .with(:path).returns(:version)
    assert_equal :version, inst.send(:extract_version, :path)
  end

  def test_v8
    inst = inst_
    assert_equal '8.1.0.0', inst.send(:v8, '1cv81')
    assert_equal '8.2.3.4', inst.send(:v8, '8.2.3.4')
    assert_equal '8.2.3.0', inst.send(:v8, '8.2.3.x')
    assert_equal '8.2.0.0', inst.send(:v8, '8.2.x.x')
    assert_equal '0.0.0.0', inst.send(:v8, '8.x.x.x')
    assert_equal '0.0.0.0', inst.send(:v8, 'x.x.x.x')
    assert_equal '0.0.0.0', inst.send(:v8, 'fake')
  end

  def test_arch
    inst = inst_
    inst.expects(:extract_arch).returns(:arch)
    assert_equal :arch, inst.arch, 'expects call :extract_arch'
  end

  def test_extract_arch_in_linux
    inst = inst_
    inst.expects(:path).returns('/opt/1C/v8.3/amd64/1cv8')
    inst.expects(:linux?).returns(true)
    assert_equal 'amd64', inst.send(:extract_arch)
  end

  def test_extract_arch_in_windows_i386
    inst = inst_
    inst.expects(:linux?).returns(false)
    inst.expects(:version64?).returns(false)
    assert_equal 'i386', inst.send(:extract_arch)
  end

  def test_extract_arch_in_windows_x86_64
    inst = inst_
    inst.expects(:linux?).returns(false)
    inst.expects(:version64?).returns(true)
    assert_equal 'x86_64', inst.send(:extract_arch)
  end

  def test_version64_txt_true
    inst = inst_
    inst.expects(:version64_exist?).with('version64.dat').returns(false)
    inst.expects(:version64_exist?).with('version64.txt').returns(true)
    assert inst.send(:version64?)
  end

  def test_version64_dat_true
    inst = inst_
    inst.expects(:version64_exist?).with('version64.dat').returns(true)
    inst.expects(:version64_exist?).with('version64.txt').never
    assert inst.send(:version64?)
  end

  def test_version64_false
    inst = inst_
    inst.expects(:version64_exist?).with('version64.dat').returns(false)
    inst.expects(:version64_exist?).with('version64.txt').returns(false)
    refute inst.send(:version64?)
  end

  def test_version64_exist
    inst = inst_
    path = mock
    path.stubs(dirname: 'fake_dir')
    inst.expects(:path).returns(path)
    File.expects(:exist?).with('fake_dir/fake_file').returns(:exists)
    assert_equal :exists, inst.send(:version64_exist?, 'fake_file')
  end

  def test_version64_exist_smoky
    inst = inst_
    path = mock
    path.stubs(dirname: 'fake_dir')
    inst.expects(:path).returns(path)
    refute inst.send(:version64_exist?, 'fake_file')
  end

  def test_v64_files
    assert_equal %w{version64.dat version64.txt},
      AssLauncher::Enterprise::BinaryWrapper::V64_FILES
  end

  def test_more_less
    other = mock
    other.expects(:version).returns(:other_version)
    version = mock
    version.expects(:"<=>").with(:other_version).returns(0)
    inst = inst_
    inst.expects(:version).returns(version)
    assert_equal 0, inst <=> other
  end

  def test_expects_basename
    inst = inst_
    AssLauncher::Enterprise.expects(:binaries).with(inst.class).returns(:binary)
    assert_equal :binary, inst.send(:expects_basename)
  end

  def test_exists?
    path = mock
    path.expects(:file?).returns(:yes)
    inst = inst_
    inst.expects(:path).returns(path)
    assert_equal :yes, inst.exists?
  end

  def test_major_v
    inst = inst_
    inst.expects(:version).returns('1.2.3.4')
    assert_equal '1.2', inst.major_v
  end

  def test_to_command
    AssLauncher::Support::Shell::Command.expects(:new).\
      with(:path, :args, :opts).returns(:command)
    path = mock
    path.expects(:to_s).returns(:path)
    inst = inst_
    inst.expects(:path).returns(path)
    assert_equal :command, inst.send(:to_command, :args, :opts)
  end

  def test_to_script
    String.any_instance.expects(:to_cmd).returns('path')
    AssLauncher::Support::Shell::Script.expects(:new).\
      with('path args', :opts).returns(:script)
    path = mock
    path.expects(:win_string).returns("path")
    inst = inst_
    inst.expects(:path).returns(path)
    assert_equal :script, inst.send(:to_script, :args, :opts)
    String.unstub
  end

  def test_mode
    inst = inst_
    inst.expects(:run_modes).returns([:run_mode_one, :run_mode_other])
    assert_equal 'RUN_MODE_OTHER', inst.send(:mode, :run_mode_other)
  end

  def test_mode_fail
    inst = inst_
    inst.expects(:run_modes).returns([:run_mode_one, :run_mode_other])
    assert_raises ArgumentError do
      inst.send(:mode, :bad_run_mode)
    end
  end

  def test_run_modes
    inst = inst_
    AssLauncher::Enterprise::Cli.expects(:defined_modes_for).with(inst.class).\
      returns(:defined_modes_for)
    assert_equal :defined_modes_for, inst.run_modes
  end

  def test_cli_spec
    inst = inst_
    AssLauncher::Enterprise::Cli::CliSpec.expects(:for).with(inst).\
      returns(:cli_spec)
    assert_equal :cli_spec, inst.cli_spec
    assert_equal :cli_spec, inst.cli_spec
  end

  def test_build_args
    zonde = {}
    inst= inst_
    AssLauncher::Enterprise::Cli::ArgumentsBuilder.expects(:build_args)\
      .with(inst, :run_mode).yields(zonde).returns(:args)
    assert_equal(:args, inst.build_args(:run_mode) do |z|
      z[:executed] = true
    end)
    assert zonde[:executed]
  end

  def test_initialize
    cls.any_instance.expects(:expects_basename).returns(File.basename(__FILE__))
    inst = cls.new(__FILE__)
    assert_equal AssLauncher::Support::Platforms.path(__FILE__), inst.path
  end

  def test_initialize_fail_path_not_file
    assert_raises ArgumentError do
      cls.new('.')
    end
  end

  def test_initialize_fail_unexpected_basename
    cls.any_instance.expects(:expects_basename).returns('v8i.exe')
    assert_raises ArgumentError do
      cls.new(__FILE__)
    end
  end
end

class TestThinClient < Minitest::Test

  def cls
    AssLauncher::Enterprise::BinaryWrapper::ThinClient
  end

  def inst_
    Class.new(cls) do
      def initialize

      end
    end.new
  end

  def test_accepted_connstr
    assert_equal [:file, :server, :http], inst_.accepted_connstr
  end

  def test_script
    inst = inst_
    inst.expects(:to_script).with("enterprise arg1 arg2", {}).returns(:script)
    inst.expects(:mode).with(:enterprise).returns(:enterprise)
    assert_equal :script, inst.script('arg1 arg2')
  end

  def test_command
    AssLauncher::Enterprise::BinaryWrapper::ThickClient.any_instance
      .expects(:command).with(:enterprise, :args, {o1:'', o2:''}).yields(:zond)
    inst_.command(:args, {o1:'', o2:''}) do |z|
      assert_equal :zond, z
    end
  end
end

class TestThickClient < Minitest::Test

  def cls
    AssLauncher::Enterprise::BinaryWrapper::ThickClient
  end

  def inst_
    Class.new(cls) do
      def initialize

      end
    end.new
  end

  def test_accepted_connstr
    assert_equal [:file, :server], inst_.accepted_connstr
  end

  def test_script
    inst = inst_
    inst.expects(:to_script).with("run_mode arg1 arg2", {}).returns(:script)
    inst.expects(:mode).with(:run_mode).returns(:run_mode)
    assert_equal :script, inst.script(:run_mode, 'arg1 arg2')
  end

  def test_to_command_with_block
    zonde = {}
    block = lambda {|z| z[:call] = :yes}
    inst = inst_
    inst.expects(:mode).returns(:run_mode)
    inst.expects(:build_args).with(:run_mode).\
      yields(zonde).returns([:arg1, :arg2, :arg3])
    inst.expects(:to_command).\
      with([:run_mode, :arg0, :arg1, :arg2, :arg3], {options:''}).\
      returns(:command)
    assert_equal :command, inst.command(:run_mode, [:arg0], options:'', &block)
    assert_equal :yes, zonde[:call]
  end

  def test_to_command_without_block
    inst = inst_
    inst.expects(:mode)
    inst.expects(:build_args).never
    inst.expects(:to_command).returns(:command)
    assert_equal :command, inst.command(nil)
  end

  def test_command_in_createinfobase_mode
    inst = inst_
    inst.expects(:mode).with(:createinfobase).returns(:createinfobase)
    inst.expects(:verify_createinfobase_param_order!).with([:createinfobase, :args])
    inst.expects(:to_command).returns(:command)
    assert_equal :command, inst.command(:createinfobase, [:args])
  end

  def test_command_in_not_createinfobase_mode
    inst = inst_
    inst.expects(:mode).with(:non_createinfobase).returns(:non_createinfobase)
    inst.expects(:verify_createinfobase_param_order!).never
    inst.expects(:to_command).returns(:command)
    assert_equal :command, inst.command(:non_createinfobase, [:args])
  end

  def test_verify_createinfobase_param_order!
    inst = inst_
    inst.expects(:parse_cs).with(1).returns(:cs)
    inst.expects(:good_cs?).with(:cs).returns(true)
    assert_equal [0, 1], inst.send(:verify_createinfobase_param_order!, [0, 1])

    inst = inst_
    inst.expects(:parse_cs).with(1).returns(:cs)
    inst.expects(:good_cs?).with(:cs).returns(false)
    e = assert_raises ArgumentError do
      inst.send(:verify_createinfobase_param_order!, [0, 1])
    end
    assert_match(/:createinfobase expects file or server/,
                 e.message)
  end

  def test_good_cs?
    refute inst_.send(:good_cs?, nil)
    srv_cs = mock
    srv_cs.expects(:is?).with(:file).returns(false)
    srv_cs.expects(:is?).with(:server).returns(true)
    assert inst_.send(:good_cs?, srv_cs)

    file_cs = mock
    file_cs.expects(:is?).with(:file).returns(true)
    file_cs.expects(:is?).with(:server).never
    assert inst_.send(:good_cs?, file_cs)

    other_cs = mock
    other_cs.expects(:is?).with(:file).returns(false)
    other_cs.expects(:is?).with(:server).returns(false)
    refute inst_.send(:good_cs?, other_cs)
  end

  def test_parse_cs
    inst = inst_
    cs = inst.send(:parse_cs, 'bad connection_string')
    assert_nil cs

    cs = inst.send(:parse_cs, "File='path'")
    assert cs.is? :file

    cs = inst.send(:parse_cs, "File=\"path\"")
    assert cs.is? :file

    cs = inst.send(:parse_cs, "srvr=\"host\";ref=\"infobase\"")
    assert cs.is? :server
  end

end
