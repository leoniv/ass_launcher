# encoding: utf-8
require 'test_helper'

class BinaryWrapperTest < Minitest::Test
  def test_fail
    raise 'FIXME'
  end

  def test_run_as_command
    _logger = mock
    _logger.expects(:debug)
    command = mock
    command.expects(:cmd)
    command.expects(:args)
    mod.expects(:logger).returns(_logger)
    AssLauncher::Support::Shell::ProcessHolder.expects(:run)\
      .with(command, :options).returns(:process_holder)
    assert_equal :process_holder, mod.run_as_command(command, :options)
  end

  def test_run_as_script
    _logger = mock
    _logger.expects(:debug).twice
    command = mock
    command.expects(:cmd)
    command.expects(:args)
    command.expects(:to_s)
    mod.expects(:logger).returns(_logger).twice
    AssLauncher::Support::Shell::ProcessHolder.expects(:run)\
      .with(command, :options).returns(:process_holder)
    assert_equal :process_holder, mod.run_as_script(command, :options)
  end
end
