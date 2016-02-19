# encoding: utf-8
require 'test_helper'

class StringTest < Minitest::Test
  def test_escape_in_windows
    AssLauncher::Support::Platforms.expects(:windows?).returns(true)
    assert_equal '"string"', 'string'.escape
  end

  def test_escape_in_unix_test
    AssLauncher::Support::Platforms.expects(:windows?).returns(false)
    Shellwords.expects(:escape).with('string').returns('string')
    assert_equal 'string', 'string'.escape
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
    mock_logger = mock()
    mock_logger.expects(:debug).with("Executing ass '#{cmd}'")
    mock_logger.expects(:debug).with('Executing ass success')
    mod.expects(:logger).returns(mock_logger).twice
    mock_exitstat = mock()
    mock_exitstat.expects(:exitstatus).returns(0)
    mock_exec_strat = mock
    mock_exec_strat.expects(:run_command).with('cmd string').returns(['stdout','stderr',mock_exitstat])
    mod.expects(:execution_strategy).returns(mock_exec_strat)
    assert mod.dirtyrun_ass(cmd).success?
  end

  def test_dirtyrun_ass_fail
    cmd = 'kiking_ass'
    mock_logger = mock()
    mock_logger.expects(:debug).with("Executing ass '#{cmd}'")
    mock_logger.expects(:error).with("Executing ass '#{cmd}'")
    mock_logger.expects(:warn)
    mod.expects(:logger).returns(mock_logger).times(3)
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
    mod.expects(:logginig_assout).with(mock_assrunresult)

    assert_equal mock_assrunresult, mod.run_ass(cmd, options)
  end

  def test_logginig_assout_success
    result = AssLauncher::Support::Shell::RunAssResult.new(:cmd, :out, 0)
    result.expects(:expected_assout?).returns(true)
    result.expects(:expected_assout).returns('expected_assout').twice
    result.expects(:assout).returns('assout').twice

    logger = mock()
    logger.expects(:debug).with("expects ass output: 'expected_assout'")
    logger.expects(:debug).with("ass output: assout")

    mod.expects(:logger).returns(logger).twice
    mod.send(:logginig_assout, result)
  end

  def test_logginig_assout_fail
    result = AssLauncher::Support::Shell::RunAssResult.new(:cmd, :out, 0)
    result.expects(:expected_assout?).returns(false)
    result.expects(:expected_assout).returns('expected_assout')
    result.expects(:assout).returns('assout')

    logger = mock()
    logger.expects(:error).with('Unexpected ass out')
    logger.expects(:warn).with("expects ass output: 'expected_assout'")
    logger.expects(:warn).with("ass output: assout")

    mod.expects(:logger).returns(logger).times(3)
    mod.send(:logginig_assout, result)
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
