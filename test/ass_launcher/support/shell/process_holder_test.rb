# encoding: utf-8
require 'test_helper'

class ProcessHolderTest < Minitest::Test
  def cls
    AssLauncher::Support::Shell::ProcessHolder
  end

  def setup
    cls.process_list.clear
  end

  def test_process_list
    assert cls.process_list.is_a? Array
    assert_equal 0, cls.process_list.size
    cls.process_list << :thread
    assert_equal 1, cls.process_list.size
  end

  def mock_command(cmd, args)
    command = mock.responds_like_instance_of(AssLauncher::Support::Shell::Command)
    command.expects(:cmd).returns(cmd)
    command.expects(:args).returns(args)
    command
  end

  def test_cmd_exe_with_k?
    command = mock_command('bla\\cmd.exe',['/k','bla'])
    assert cls.cmd_exe_with_k?(command)
    command = mock_command('blacmd.exe',['/k','bla'])
    refute cls.cmd_exe_with_k?(command)
  end

  def test_cmd_exe_with_c?
    command = mock_command('bla\\cmd.exe',['/c','bla'])
    assert cls.cmd_exe_with_c?(command)
    command = mock_command('blacmd.exe',['/c','bla'])
    refute cls.cmd_exe_with_c?(command)
  end

  def test_run
    command = mock
    cls.expects(:cmd_exe_with_k?).with(command).returns(false)
    mock_holder = mock
    mock_holder.expects(:run).returns(mock_holder)
    cls.expects(:new).with(command, {}).returns(mock_holder)
    cls.expects(:reg_process).with(mock_holder).returns(false)
    assert_equal mock_holder, cls.run(command, {})
  end

  def test_reg_process
    process_list = mock
    process_list.expects(:"<<").with(:fake_process)
    cls.expects(:process_list).returns(process_list)
    cls.send(:reg_process, :fake_process)
  end

  def test_run_fail
    command = mock
    cls.expects(:cmd_exe_with_k?).with(command).returns(true)
    assert_raises AssLauncher::Support::Shell::ProcessHolder::RunProcessError do
      cls.run(command)
    end
  end

  def test_initialize
    cls.any_instance.expects(:windows?).returns(false)
    command = command_not_runned
    inst = cls.new(command, :options)
    assert_equal command, inst.command
    assert_equal :options, inst.options
  end

  def test_initialize_in_windows
    cls.any_instance.expects(:windows?).returns(true)
    command = command_not_runned
    inst = cls.new(command)
    assert_equal command, inst.command
    assert inst.options[:new_pgroup]
  end

  def test_inst_run
    popen3_thread = mock
    popen3_thread.expects(:pid).returns(:pid)
    inst = cls.new(command_not_runned)
    out = StringIO.new
    err = StringIO.new
    inst.expects(:run_process).returns([popen3_thread, out, err])
    inst.expects(:wait_process_in_thread).with(out, err).\
      returns(:thread)
    assert_equal inst, inst.run
    assert_equal popen3_thread, inst.popen3_thread
    assert_equal :pid, inst.pid
    assert_equal :thread, inst.thread
  end

  def test_wait_process_in_thread
    out = StringIO.new('out')
    err = StringIO.new('err')
    command = mock
    command.expects(:exit_handling).with(:exitstatus, 'out', 'err').returns(:result)
    command.expects(:running?).returns(false)
    command.expects(:send).with(:process_holder=, kind_of(cls))
    popen3_thread = mock
    popen3_thread.expects(:join)

    inst = cls.new(command)
    inst.expects(:popen3_thread).returns(popen3_thread)
    inst.expects(:exitstatus).returns(:exitstatus)
    assert_instance_of Thread, inst.send(:wait_process_in_thread, out, err).join
    assert_equal :result, inst.result
  end

  def test_wait_process_in_thread_fail
    out = StringIO.new('out')
    err = StringIO.new('err')
    command = mock
    command.expects(:exit_handling).with(:exitstatus, 'out', 'err').\
      raises(StandardError)
    command.expects(:running?).returns(false)
    command.expects(:send).with(:process_holder=, kind_of(cls))
    popen3_thread = mock
    popen3_thread.expects(:join)

    inst = cls.new(command)
    inst.expects(:popen3_thread).returns(popen3_thread)
    inst.expects(:exitstatus).returns(:exitstatus)
    assert_instance_of Thread, inst.send(:wait_process_in_thread, out, err).join
    assert_instance_of StandardError, inst.result
  end


  def test_exitststus
    popen3_thread = mock
    popen3_thread.expects(:value).returns('100')

    inst = cls.new(command_not_runned)
    inst.expects(:popen3_thread).returns(popen3_thread)
    assert_equal 100, inst.send(:exitstatus)
  end

  def test_run_process
    command = mock.responds_like_instance_of(AssLauncher::Support::Shell::Command)
    command.expects(:cmd).returns(:cmd)
    command.expects(:args).returns([]).times(3)
    command.expects(:running?).returns(false)
    command.expects(:send).with(:process_holder=, kind_of(cls))
    Open3.expects(:popen3).with(:cmd, '', :options).returns [:r1, :r2, :r3, :popen3_thread]
    inst = cls.new(command)
    inst.expects(:options).returns(:options)
    assert_equal [:popen3_thread, :r2, :r3], inst.send(:run_process)
  end

  def test_kill_alive
    inst = cls.new(command_not_runned)
    inst.expects(:alive?).returns(true)
    cls.expects(:cmd_exe_with_c?).returns(false)
    Process.expects(:kill).with('KILL',:pid)
    inst.expects(:pid).returns(:pid)
    inst.expects(:wait).returns(inst)
    assert_equal inst, inst.kill
    Process.unstub(:kill)
  end

  def test_kill_alive_fail
    inst = cls.new(command_not_runned)
    inst.expects(:alive?).returns(true)
    cls.expects(:cmd_exe_with_c?).returns(true)
    assert_raises AssLauncher::Support::Shell::ProcessHolder::KillProcessError do
      inst.kill
    end
  end

  def test_kill_dead
    Process.expects(:kill).never
    inst = cls.new(command_not_runned)
    inst.expects(:alive?).returns(false)
    assert_equal inst, inst.kill
  end

  def test_wait_alive
    thread = mock
    thread.expects(:join)
    inst = cls.new(command_not_runned)
    inst.expects(:alive?).returns(true)
    inst.expects(:thread).returns(thread)
    assert_equal inst, inst.wait
  end

  def command_not_runned
    command = mock
    command.expects(:running?).returns(false)
    command.expects(:process_holder=).with(kind_of(cls))
    command
  end

  def test_wait_dead
    inst = cls.new(command_not_runned)
    inst.expects(:alive?).returns(false)
    inst.expects(:thread).never
    assert_equal inst, inst.wait
  end

  def test_alive?
    thread = mock
    thread.expects(:alive?).returns(true)
    inst = cls.new(command_not_runned)
    inst.expects(:thread).returns(thread)
    inst.expects(:running?).returns(true)
    assert inst.alive?
  end

  def test_running?
    pid = mock
    pid.expects(:nil?).returns(false)
    inst = cls.new(command_not_runned)
    inst.expects(:pid).returns(pid)
    assert inst.running?
  end

  def test_alive_fail
    inst = cls.new(command_not_runned)
    inst.expects(:running?).returns(false)
    assert_raises AssLauncher::Support::Shell::ProcessHolder::ProcessNotRunning do
      assert inst.alive?
    end
  end
end
