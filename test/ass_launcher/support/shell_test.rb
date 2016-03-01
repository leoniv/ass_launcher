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

  def test_dirtyrun_ass_sucsess
    cmd = 'cmd string'
    mod.expects(:logger).never
    mock_cmd_string = mock()
    mock_exitstat = mock()
    mock_exitstat.expects(:exitstatus).returns(0)
    mock_cmd_string.expects(:execute).returns([:out, :err, mock_exitstat])
    mod.expects(:cmd_string).with(cmd).returns(mock_cmd_string)
    mod.expects(:loggining_runass).with() {|result| result.is_a? AssLauncher::Support::Shell::RunAssResult}
    assert mod.dirtyrun_ass(cmd).success?
  end

  def test_dirtyrun_ass_fail
    cmd = 'kiking_ass'
    mod.expects(:loggining_runass).with() {|result| result.is_a? AssLauncher::Support::Shell::RunAssResult}
    mock_cmd_string = mock
    mock_cmd_string.expects(:execute).\
      raises(*mod.send(:exception_meaning_command_not_found))
    mod.expects(:cmd_string).with(cmd).returns(mock_cmd_string)
    refute mod.dirtyrun_ass(cmd).success?
  end

  def test_run_ass_sucsess
    cmd = 'ass cmd'
    options = { out_encoding:'encoding',
                expected_assout:/expected_assout/
    }
    mock_assoutfile = mock()
    mock_assoutfile.expects(:to_s).returns('out_file')
    mock_assoutfile.expects(:read).returns('ass out text')
    AssLauncher::Support::Shell::AssOutFile.expects(:new).with('encoding').returns(mock_assoutfile)
    mock_assrunresult = mock()
    mock_assrunresult.expects(:send).with(:expected_assout=,/expected_assout/)
    mock_assrunresult.expects(:send).with(:assout=,'ass out text')
    mod.expects(:dirtyrun_ass).with("#{cmd} /OUT\"out_file\" /DisableStartupDialogs /DisableStartupMessages").returns(mock_assrunresult)
    mod.expects(:loggining_assout).with(mock_assrunresult)

    assert_equal mock_assrunresult, mod.run_ass(cmd, options)
  end

  def test_loggining_assout_success
    result = AssLauncher::Support::Shell::RunAssResult.new(:cmd, :out, 0)
    result.expects(:expected_assout?).returns(true)
    result.expects(:expected_assout).returns('expected_assout').twice

    logger = mock()
    logger.expects(:debug).with("expects ass output: 'expected_assout'")

    mod.expects(:logger).returns(logger)
    mod.expects(:loggining_assout_output).with(result)
    mod.send(:loggining_assout, result)
  end

  def test_loggining_assout_fail
    result = AssLauncher::Support::Shell::RunAssResult.new(:cmd, :out, 0)
    result.expects(:expected_assout?).returns(false)
    result.expects(:expected_assout).returns('expected_assout')
    result.expects(:assout).returns('assout')

    logger = mock()
    logger.expects(:error).with('Unexpected ass out')
    logger.expects(:warn).with("expects ass output: 'expected_assout'")
    logger.expects(:warn).with("ass output: assout")

    mod.expects(:logger).returns(logger).times(3)
    mod.send(:loggining_assout, result)
  end

  def test_loggining_assout_output_saccess
    result = mock
    result.expects(:success?).returns(true)
    result.expects(:assout).returns(:ass_out).twice
    mock_logger = mock
    mock_logger.expects(:debug).with(){|arg| arg == 'ass output: ass_out'}
    mod.expects(:logger).returns(mock_logger)
    mod.send(:loggining_assout_output,result)
  end

  def test_loggining_assout_output_not_succsess
    result = mock
    result.expects(:success?).returns(false)
    result.expects(:assout).returns(:ass_out).twice
    mock_logger = mock
    mock_logger.expects(:warn).with(){|arg| arg == 'ass output: ass_out'}
    mod.expects(:logger).returns(mock_logger)
    mod.send(:loggining_assout_output,result)
  end

  def test_logginig_runass_saccsess
    result = mock
    result.expects(:success?).returns(true)
    mock_logger = mock
    mock_logger.expects(:debug).with('Executing ass success')
    mod.expects(:logger).returns(mock_logger)
    mod.send(:loggining_runass,result)
  end

  def test_logginig_runass_not_saccsess
    result = mock
    result.expects(:success?).returns(false)
    result.expects(:cmd).returns('cmd string')
    result.expects(:out).returns('out string').twice
    mock_logger = mock
    mock_logger.expects(:error).with('Executing ass \'cmd string\'')
    mock_logger.expects(:warn).with('stderr output: out string')
    mod.expects(:logger).returns(mock_logger).twice
    mod.send(:loggining_runass,result)
  end

  def test_cmd_string_in_win
    mod.expects(:windows?).returns(:true)
    mod.expects(:cygwin?).never
    mock_cmd_s = mock
    AssLauncher::Support::Shell::CmdScript.expects(:new).returns(mock_cmd_s)
    assert_equal mock_cmd_s, mod.cmd_string('')
  end

  def test_cmd_string_in_cygwin
    mod.expects(:windows?).returns(false)
    mod.expects(:cygwin?).returns(true)
    mock_cmd_s = mock
    AssLauncher::Support::Shell::CmdScript.expects(:new).returns(mock_cmd_s)
    assert_equal mock_cmd_s, mod.cmd_string('')
  end

  def test_cmd_string_in_linux
    mod.expects(:windows?).returns(false)
    mod.expects(:cygwin?).returns(false)
    mock_cmd_s = mock
    AssLauncher::Support::Shell::CmdString.expects(:new).returns(mock_cmd_s)
    assert_equal mock_cmd_s, mod.cmd_string('')
  end
end

class CmdStringTest < Minitest::Test

  def setup
    @inst = cls.new('')
  end

  def cls
    AssLauncher::Support::Shell::CmdString
  end

  def test_initialize
    inst = cls.new('run_ass_str_')
    assert_equal 'run_ass_str_', inst.run_ass_str
    assert_equal 'run_ass_str_', inst.command
  end

  def test_to_s
    @inst.expects(:command)
    @inst.to_s
  end

  def test_execute
    cmd = 'command for run'
    inst = cls.new(cmd)
    logger = mock()
    logger.expects(:debug).with("Executing command: '#{cmd}'")
    execution_strategy = mock()
    execution_strategy.expects(:run_command).with(cmd).returns(true)
    inst.expects(:logger).returns(logger)
    inst.expects(:execution_strategy).returns(execution_strategy)
    assert inst.execute
  end

  def test_execution_strategy
    assert_respond_to @inst.execution_strategy, :run_command
  end
end

class CmdScriptTest < Minitest::Test
  def cls
    AssLauncher::Support::Shell::CmdScript
  end

  def test_initialize
    cmd = 'string for run'
    tempfile = mock()
    tempfile.expects(:open)
    tempfile.expects(:write).with(cmd)
    tempfile.expects(:close)
    tempfile.expects(:path).returns('.')
    Tempfile.expects(:new).with(%w'run_ass_script .cmd').returns(tempfile)
    inst = cls.new(cmd)
    assert_equal tempfile, inst.file
    assert_kind_of AssLauncher::Support::Platforms::PathnameExt, inst.path
  end

  def test_command_in_linux
    cmd = 'cmd string'
    tempfile = mock()
    tempfile.expects(:open)
    tempfile.expects(:write).with(cmd)
    tempfile.expects(:close)
    tempfile.expects(:path).returns('.')
    Tempfile.expects(:new).with(%w'run_ass_script .cmd').returns(tempfile)
    inst = cls.new(cmd)
    inst.expects(:windows? => false, :cygwin? => false)
    assert_equal "sh #{inst.path.win_string}", inst.command
  end

  def test_command_in_windows
    cmd = 'cmd string'
    tempfile = mock()
    tempfile.expects(:open)
    tempfile.expects(:write).with(cmd)
    tempfile.expects(:close)
    tempfile.expects(:path).returns('.')
    Tempfile.expects(:new).with(%w'run_ass_script .cmd').returns(tempfile)
    inst = cls.new(cmd)
    inst.expects(:windows? => true, :cygwin? => false)
    assert_equal "cmd /C \"#{inst.path.win_string}\"", inst.command
  end

  def test_command_in_cygwin
    cmd = 'cmd string'
    tempfile = mock()
    tempfile.expects(:open)
    tempfile.expects(:write).with(cmd)
    tempfile.expects(:close)
    tempfile.expects(:path).returns('.')
    Tempfile.expects(:new).with(%w'run_ass_script .cmd').returns(tempfile)
    inst = cls.new(cmd)
    inst.expects(:cygwin? => true)
    assert_equal "cmd /C \"#{inst.path.win_string}\"", inst.command
  end

  def test_execute_in_cygwin
    cmd = 'cmd string'
    mock_logger = mock
    mock_logger.expects(:debug)
    tempfile = mock()
    tempfile.expects(:open)
    tempfile.expects(:write).with(cmd)
    tempfile.expects(:close)
    tempfile.expects(:path).returns('.')
    tempfile.expects(:unlink)
    Tempfile.expects(:new).with(%w'run_ass_script .cmd').returns(tempfile)
    inst = cls.new(cmd)
    inst.expects(:logger).returns(mock_logger)
    inst.expects(:cygwin?).returns(true)
    out = mock; out.expects(:encode!).with('utf-8', 'cp866')
    err = mock; err.expects(:encode!).with('utf-8', 'cp866')
    AssLauncher::Support::Shell::CmdString.any_instance\
      .expects(:execute).returns([out, err, :status])
    Tempfile.unstub(:new)
    assert_equal [out,err,:status], inst.execute
  end

  def test_execute_in_windows_or_linux
    cmd = 'cmd string'
    mock_logger = mock
    mock_logger.expects(:debug)
    tempfile = mock()
    tempfile.expects(:open)
    tempfile.expects(:write).with(cmd)
    tempfile.expects(:close)
    tempfile.expects(:path).returns('.')
    tempfile.expects(:unlink)
    Tempfile.expects(:new).with(%w'run_ass_script .cmd').returns(tempfile)
    inst = cls.new(cmd)
    inst.expects(:logger).returns(mock_logger)
    inst.expects(:cygwin?).returns(false)
    out = mock; out.expects(:encode!).never
    err = mock; err.expects(:encode!).never
    AssLauncher::Support::Shell::CmdString.any_instance\
      .expects(:execute).returns([out, err, :status])
    Tempfile.unstub(:new)
    assert_equal [out,err,:status], inst.execute
  end
end

class RunAssResultTest < Minitest::Test
  def cls
    AssLauncher::Support::Shell::RunAssResult
  end

  def test_initialize
    inst = cls.new('_cmd_', '_out_', '_exitstatus_')
    assert_equal '_cmd_', inst.cmd
    assert_equal '_out_', inst.out
    assert_equal '_exitstatus_', inst.exitstatus
  end

  def test_cut_ass_out
    inst = cls.new('','',0)
    inst.expects(:assout).returns('X'*80).twice
    assert_equal 'X'*80, inst.send(:cut_assout)
    inst.expects(:assout).returns('X'*81).twice
    assert_equal 'X'*80+'...', inst.send(:cut_assout)
  end

  def test_sucsess_false_on_exitstatus
    inst = cls.new('','','')
    inst.expects(:exitstatus).returns(1)
    inst.expects(:expected_assout?).never
    refute inst.success?
  end

  def test_sucsess_false_on_unexpected_assout
    inst = cls.new('','','')
    inst.expects(:exitstatus).returns(0)
    inst.expects(:expected_assout?).returns(false)
    refute inst.success?
  end

  def test_sucsess_true
    inst = cls.new('','','')
    inst.expects(:exitstatus).returns(0)
    inst.expects(:expected_assout?).returns(true)
    assert inst.success?
  end

  def test_expected_assout=()
    inst = cls.new('','','')
    assert inst.send(:expected_assout=,nil).nil?
    assert_raises ArgumentError do
      inst.send(:expected_assout=,'bad regex')
    end
    regex = //
    assert_equal regex, inst.send(:expected_assout=,regex)
    assert_equal regex, inst.expected_assout
  end

  def test_without_match_expected_assout?
    inst = cls.new('','','')
    inst.expects(:expected_assout).returns(nil)
    assert inst.expected_assout?

    inst.expects(:expected_assout).returns(//)
    inst.expects(:exitstatus).returns(1)
    assert inst.expected_assout?
  end

  def test_true_expected_assout?
    inst = cls.new('','','')
    inst.expects(:expected_assout).returns(/.*/).twice
    inst.expects(:exitstatus).returns(0)
    inst.expects(:assout).returns('any string')
    assert inst.expected_assout?
  end

  def test_false_expected_assout?
    inst = cls.new('','','')
    inst.expects(:expected_assout).returns(/.+/).twice
    inst.expects(:exitstatus).returns(0)
    inst.expects(:assout).returns('')
    refute inst.expected_assout?
  end


  def test_unexpected_assout_verify!
    inst = cls.new('','','')
    inst.expects(:expected_assout?).returns(false)
    inst.expects(:success?).never
    inst.expects(:cut_assout).returns('ass out')
    assert_raises AssLauncher::Support::Shell::RunAssResult::UnexpectedAssOut do
      inst.verify!
    end
  end

  def test_runasserror_verify!
    inst = cls.new('','','')
    inst.expects(:expected_assout?).returns(true)
    inst.expects(:success?).returns(false)
    inst.expects(:cut_assout).returns('ass out')
    inst.expects(:out).returns('out')
    assert_raises AssLauncher::Support::Shell::RunAssResult::RunAssError do
      inst.verify!
    end
  end

  def test_verify!
    inst = cls.new('','','')
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
