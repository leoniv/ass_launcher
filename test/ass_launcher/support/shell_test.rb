# encoding: utf-8
require 'test_helper'

class StringTest < Minitest::Test
  def test_escape
    assert_equal 'str\\ ing', 'str ing'.escape
  end

  def test_to_cmd_in_linux
    AssLauncher::Support::Platforms.expects(:windows?).returns(false)
    AssLauncher::Support::Platforms.expects(:cygwin?).returns(false)
    str = 'str ing'
    assert_equal 'str\\ ing', str.to_cmd
  end

  def test_to_cmd_in_windows_or_cygwin
    AssLauncher::Support::Platforms.expects(:windows?).returns(false)
    AssLauncher::Support::Platforms.expects(:cygwin?).returns(true)
    str = 'string'
    str.expects(:escape).never
    assert_equal '"string"', str.to_cmd
  end
end

class AssLauncherConfigTest < Minitest::Test
  def test_config
    assert_instance_of AssLauncher::Configuration, AssLauncher.config
    assert_equal AssLauncher.config, AssLauncher.config
    AssLauncher.configure do |c|
      assert_equal c, AssLauncher.config
    end
  end
end

class ConfigurationTest < Minitest::Test
  def test_logger
    assert_kind_of Logger,  AssLauncher.config.logger
  end

  def test_logger=()
    assert_raises ArgumentError do
      AssLauncher.config.logger = nil
    end

    l = Logger.new($stderr)
    AssLauncher.config.logger = l
    assert_equal l, AssLauncher.config.logger
  end
end

class TestLoggining < Minitest::Test
  class Loggining
    include AssLauncher::Loggining
  end
  def test_logger
    assert_equal Loggining.logger, AssLauncher.config.logger
    assert_equal Loggining.new.logger, AssLauncher.config.logger
  end
end

class ShellTest < Minitest::Test

  def mod
    AssLauncher::Support::Shell
  end

  def test_include?
    assert mod.include? AssLauncher::Loggining
    assert mod.include? Methadone::SH
  end
end

class RunAssResultTest < Minitest::Test
  def cls
    AssLauncher::Support::Shell::RunAssResult
  end

  def test_initialize
    inst = cls.new(:exitstatus, :out, :err, :assout)
    assert_equal :exitstatus, inst.exitstatus
    assert_equal :out, inst.out
    assert_equal :err, inst.err
    assert_equal :assout, inst.assout
  end

  def test_cut_ass_out
    inst = cls.new(0,'','','')
    inst.expects(:assout).returns('X'*640).twice
    assert_equal 'X'*640, inst.send(:cut_assout)
    inst.expects(:assout).returns('X'*641).twice
    assert_equal 'X'*640+'...', inst.send(:cut_assout)
  end

  def test_sucsess_false_on_exitstatus
    inst = cls.new('','','','')
    inst.expects(:exitstatus).returns(1)
    inst.expects(:expected_assout?).never
    refute inst.success?
  end

  def test_sucsess_false_on_unexpected_assout
    inst = cls.new('','','','')
    inst.expects(:exitstatus).returns(0)
    inst.expects(:expected_assout?).returns(false)
    refute inst.success?
  end

  def test_sucsess_true
    inst = cls.new('','','','')
    inst.expects(:exitstatus).returns(0)
    inst.expects(:expected_assout?).returns(true)
    assert inst.success?
  end

  def test_expected_assout=()
    inst = cls.new('','','','')
    assert_equal nil, inst.expected_assout = nil
    assert_raises ArgumentError do
      inst.expected_assout = 'bad regex'
    end
    regex = //
    assert_equal regex, inst.expected_assout = regex
    assert_equal regex, inst.expected_assout
  end

  def test_without_match_expected_assout?
    inst = cls.new('','','','')
    inst.expects(:expected_assout).returns(nil)
    assert inst.expected_assout?

    inst.expects(:expected_assout).returns(//)
    inst.expects(:exitstatus).returns(1)
    assert inst.expected_assout?
  end

  def test_true_expected_assout?
    inst = cls.new('','','','')
    inst.expects(:expected_assout).returns(/.*/).twice
    inst.expects(:exitstatus).returns(0)
    inst.expects(:assout).returns('any string')
    assert inst.expected_assout?
  end

  def test_false_expected_assout?
    inst = cls.new('','','','')
    inst.expects(:expected_assout).returns(/.+/).twice
    inst.expects(:exitstatus).returns(0)
    inst.expects(:assout).returns('')
    refute inst.expected_assout?
  end


  def test_unexpected_assout_verify!
    inst = cls.new('','','','')
    inst.expects(:expected_assout?).returns(false)
    inst.expects(:success?).never
    inst.expects(:cut_assout).returns('ass out')
    assert_raises AssLauncher::Support::Shell::RunAssResult::UnexpectedAssOut do
      inst.verify!
    end
  end

  def test_runasserror_verify!
    inst = cls.new('','','','')
    inst.expects(:expected_assout?).returns(true)
    inst.expects(:success?).returns(false)
    inst.expects(:cut_assout).returns('ass out')
    inst.expects(:err).returns('err')
    assert_raises AssLauncher::Support::Shell::RunAssResult::RunAssError do
      inst.verify!
    end
  end

  def test_verify!
    inst = cls.new('','','','')
    inst.expects(:expected_assout?).returns(true)
    inst.expects(:success?).returns(true)
    assert_equal inst, inst.verify!
  end
end

class AssOutFileTest < Minitest::Test
  def cls
    AssLauncher::Support::Shell::AssOutFile
  end

  def test_initialize
    inst = cls.new('encoding')
    assert_equal 'encoding', inst.encoding
    inst = cls.new()
    assert_equal Encoding::CP1251, inst.encoding
    assert_instance_of Tempfile, inst.file
    assert inst.file.closed?
    assert_kind_of AssLauncher::Support::Platforms::PathnameExt, inst.path
  end

  def test_to_s
    inst = cls.new
    inst.path.expects(:to_s).returns('path')
    assert_equal 'path', inst.to_s
  end

  def test_read_good
    mock_file = StringIO.new
    mock_file.expects(:open)
    mock_file.expects(:read).returns('string')
    mock_file.expects(:close).twice
    mock_file.expects(:path).returns('.')
    mock_file.expects(:unlink)
    Tempfile.expects(:new).returns(mock_file)
    inst = cls.new
    inst.expects(:linux?).returns(true)
    assert_equal 'string', inst.read
  end

  def test_read_fail
    mock_file = StringIO.new
    mock_file.expects(:close).twice
    mock_file.expects(:path).returns('.')
    Tempfile.expects(:new).returns(mock_file)
    inst = cls.new
    assert_raises NoMethodError do
      inst.read
    end
  end
end

class TestCommand < Minitest::Test
  def cls
    AssLauncher::Support::Shell::Command
  end

  def test_initialize_default_options
    cls.any_instance.expects(:_silent_mode).returns([:silent_mode])
    cls.any_instance.expects(:_ass_out_file).returns(:assout_file)
    options = {}
    args = [:arg1]
    inst = cls.new(:cmd, args, options)
    assert_equal :cmd, inst.cmd
    assert_equal [:arg1, :silent_mode], inst.args
    assert_equal :assout_file, inst.send(:ass_out_file)
    assert_equal({capture_assout: true, silent_mode: true},\
      inst.options)
  end

  def test_silent_mode
    inst = Class.new(cls) do
      def initialize

      end
    end.new
    inst.expects(:options).returns({silent_mode: false})
    assert_equal [], inst.send(:_silent_mode)
    inst.expects(:options).returns({silent_mode: true})
    assert_equal [ '/DisableStartupDialogs', '',
                   '/DisableStartupMessages', '' ],\
                   inst.send(:_silent_mode)
  end

  def test_capture_assout?
    inst = cls.new('')
    assert inst.capture_assout?

    inst = cls.new('',[], capture_assout: false)
    refute inst.capture_assout?
  end

  def test_duplicate_param_out?
    inst = Class.new(cls) do
      def initialize

      end
    end.new
    inst.expects(:args).returns(['/out'])
    inst.expects(:capture_assout?).returns(true)
    assert inst.send(:duplicate_param_out?)
  end

  def test_validate_args
    inst = Class.new(cls) do
      def initialize

      end
    end.new
    inst.expects(:duplicate_param_out?).returns(false)
    assert_nil inst.send(:validate_args)
    inst.expects(:duplicate_param_out?).returns(true)
    assert_raises ArgumentError do
      inst.send :validate_args
    end
  end

  def args_include_test(greps, expect)
    args = mock
    args.expects(:grep).with(:regex).returns(greps)
    inst = Class.new(cls) do
      def initialize

      end
    end.new
    inst.expects(:args).returns(args)
    assert_equal expect, inst.send(:args_include?, :regex)
  end

  def test_args_include?
    args_include_test([], false)
    args_include_test([1], true)
  end

  def test_ass_out_file_stringio
    inst = Class.new(cls) do
      def initialize

      end
    end.new
    inst.expects(:options).returns({capture_assout: false})
    assert_instance_of StringIO, inst.send(:_ass_out_file)
  end

  def test_ass_out_file
    inst = Class.new(cls) do
      def initialize

      end
    end.new
    inst.expects(:options).returns({capture_assout: true}).twice
    mock_file = mock
    AssLauncher::Support::Shell::AssOutFile.expects(:new).returns(mock_file)
    inst.expects(:_out_ass_argument).with(mock_file).returns(mock_file)
    assert_equal mock_file, inst.send(:_ass_out_file)
  end

  def test_out_ass_argument
    inst = Class.new(cls) do
      def initialize
        @args = []
      end
    end.new
    file = mock
    file.expects(:to_s).returns(:ass_out_file)
    assert_equal file, inst.send(:_out_ass_argument, file)
    assert_equal ['/OUT', :ass_out_file], inst.args
  end

  def test_to_s
    inst = Class.new(cls) do
      def initialize

      end
    end.new
    cmd = mock; cmd.expects(:to_s).returns('cmd')
    args = mock; args.expects(:join).with(' ').returns('args')
    inst.expects(:cmd).returns(cmd); inst.expects(:args).returns(args)
    assert_equal 'cmd args', inst.to_s
  end

  def test_exit_handling
    inst = Class.new(cls) do
      def initialize
      end
    end.new
    inst.expects(:ass_out_file).returns(StringIO.new('ass out content'))
    result = inst.exit_handling(:exitstatus, :out, :err)
    assert_instance_of AssLauncher::Support::Shell::RunAssResult, result
    assert_equal :exitstatus, result.exitstatus
    assert_equal :out, result.out
    assert_equal :err, result.err
    assert_equal 'ass out content', result.assout
  end

  def test_running?
    inst = cls.new('',[])
    refute inst.running?

    process_holder = mock
    process_holder.expects(:nil?).returns(false)
    inst = cls.new('',[])
    inst.expects(:process_holder).returns(process_holder)
    assert inst.running?
  end

  def test_run
    inst = cls.new('',[])
    inst.expects(:running?).returns(false)
    inst.expects(:process_holder).never
    AssLauncher::Support::Shell::ProcessHolder.expects(:run).\
      with(inst, :options).returns(:process_holder)
    assert_equal :process_holder, inst.run(:options)
  end

  def test_run_running
    inst = cls.new('',[])
    inst.expects(:running?).returns(true)
    inst.expects(:process_holder).returns(:process_holder)
    AssLauncher::Support::Shell::ProcessHolder.expects(:run).never
    assert_equal :process_holder, inst.run(:options)
  end
end

class TestScript < Minitest::Test

  def cls
    AssLauncher::Support::Shell::Script
  end

  def test_run
    process_holder = mock
    process_holder.expects(:wait).returns(:process_holder)
    AssLauncher::Support::Shell::Command.any_instance.expects(:run).\
      with(:options).returns(process_holder)
    inst = cls.new('')
    assert_equal :process_holder, inst.run(:options)

  end

  def test_initialize
    AssLauncher::Support::Shell::Command.any_instance.expects(:initialize).\
      with(:cmd, [], :options)
    assert_instance_of cls, cls.new(:cmd, :options)
    AssLauncher::Support::Shell::Command.unstub
  end

  def test_platforms_included
    assert cls.include? AssLauncher::Support::Platforms
  end

  def test_make_script
    inst = Class.new(cls) do
      def initialize

      end
    end.new

    tempfile = mock
    tempfile.expects(:open)
    tempfile.expects(:write).with('script content')
    tempfile.expects(:close)
    tempfile.expects(:path).returns(:tempfile_path)
    Tempfile.expects(:new).with(%w( run_ass_script .cmd )).returns(tempfile)
    platform = mock
    platform.expects(:path).with(:tempfile_path).returns(:path_extension)
    inst.expects(:platform).returns(platform)
    inst.expects(:encode).returns('script content')
    assert_equal :path_extension, inst.send(:make_script)
  end

  def test_out_ass_argument
    inst = Class.new(cls) do
      def initialize
        @args = []
      end
    end.new
    out_file = mock()
    out_file.expects(:to_s).returns(:ass_out_file.to_s)
    assert_equal out_file, inst.send(:_out_ass_argument, out_file)
    assert_equal ['/OUT', "\"#{:ass_out_file}\""], inst.\
      instance_variable_get(:@args)
  end

  def test_encode_linux
    inst = Class.new(cls) do
      def initialize
      end
    end.new
    inst.expects(:cygwin_or_windows?).returns(false)
    to_s = mock
    to_s.expects(:encode).never
    inst.expects(:to_s).returns(to_s)
    inst.send(:encode)
  end

  def test_encode_cygwin_or_windows
    inst = Class.new(cls) do
      def initialize
      end
    end.new
    inst.expects(:cygwin_or_windows?).returns(true)
    to_s = mock
    to_s.expects(:encode).with('cp866','utf-8')
    inst.expects(:to_s).returns(to_s)
    inst.send(:encode)
    assert_equal '', ''.encode('cp866', 'utf-8')
  end

  def test_to_s
    cmd_args = mock
    cmd_args.expects(:to_s).returns('cmd')
    cmd_args.expects(:join).with(' ').returns('args')
    inst = Class.new(cls) do
      def initialize(cmd_args)
        @cmd = cmd_args
        @args = cmd_args
      end
    end.new(cmd_args)
    inst.expects(:cmd).never
    inst.expects(:args).never
    assert_equal 'cmd args', inst.to_s
  end

  def test_cmd_in_linux
    inst = Class.new(cls) do
      def initialize()
      end
    end.new()
    inst.expects(:cygwin_or_windows?).returns(false)
    assert_equal 'sh', inst.cmd
  end

  def test_cmd_in_cygwin_or_windows
    inst = Class.new(cls) do
      def initialize()
      end
    end.new()
    inst.expects(:cygwin_or_windows?).returns(true)
    assert_equal 'cmd.exe', inst.cmd
  end

  def test_args_in_linux
    inst = Class.new(cls) do
      def initialize()
      end
    end.new()
    path = mock
    path.expects(:to_s).returns(:script_path)
    inst.expects(:cygwin_or_windows?).returns(false)
    inst.expects(:make_script).returns(path)
    assert_equal [:script_path], inst.args
  end

  def test_args_in_cygwin_or_windows
    inst = Class.new(cls) do
      def initialize()
      end
    end.new()
    path = mock
    path.expects(:win_string).returns(:script_path)
    inst.expects(:cygwin_or_windows?).returns(true)
    inst.expects(:make_script).returns(path)
    assert_equal ['/C',:script_path], inst.args
  end

  def test_cygwin_or_windows?
    inst = Class.new(cls) do
      def initialize()
      end
    end.new()
    p = AssLauncher::Support::Platforms
    assert_equal (p.cygwin? || p.windows?),
      inst.send(:cygwin_or_windows?)
  end

  def test_encode_out
    inst = Class.new(cls) do
      def initialize
      end
    end.new
    inst.expects(:cygwin_or_windows?).returns(true)
    out = mock
    out.expects(:encode!).with('utf-8', 'cp866')
    assert_equal out, inst.send(:encode_out, out)
  end

  def test_encode_out_fail
    inst = Class.new(cls) do
      def initialize
      end
    end.new
    inst.expects(:cygwin_or_windows?).returns(true)
    out = mock
    out.expects(:to_s).returns('out')
    out.expects(:encode!).with('utf-8', 'cp866').raises(EncodingError)
    assert_equal 'EncodingError: out', inst.send(:encode_out, out)
  end
end
