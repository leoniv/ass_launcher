# encoding: utf-8
require 'test_helper'

class ProcessHolderTest < Minitest::Test
  def cls
    AssLauncher::Support::Shell::ProcessHolder
  end

  def setup
    cls.threads_list.clear
    cls.process_list.clear
  end

  def assert_list(list)
    assert cls.send(list).is_a? Array
    assert_equal 0, cls.send(list).size
    cls.send(list) << :thread
    assert_equal 1, cls.send(list).size
  end

  def test_threads_list
    assert_list :threads_list
  end

  def test_process_list
    assert_list :process_list
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
    cls.expects(:new).returns(mock_holder)
    thread_mock = mock
    cls.expects(:run_thread).with(command, :options, mock_holder).returns(thread_mock)
    mock_holder.expects(:thread=).with(thread_mock)
    assert_equal mock_holder, cls.run(command, :options)
    assert_equal mock_holder, cls.process_list.last
  end

  def test_run_fail
    command = mock
    cls.expects(:cmd_exe_with_k?).with(command).returns(true)
    assert_raises AssLauncher::Support::Shell::ProcessHolder::RunProcessError do
      cls.run(command)
    end
  end

  def test_run_thread
    holder = mock
    cls.expects(:run_and_wait_process).with(:command, :options, holder)
    tr = cls.send(:run_thread, :command, :options, holder)
    tr.join
    assert_instance_of Thread, tr
    assert_equal 1, cls.threads_list.size
    assert_instance_of Thread, cls.threads_list.last
  end

  def test_run_thread_fail
    holder = mock
    holder.expects(:exit_handling).with(1, '', 'StandardError message')
    cls.expects(:run_and_wait_process).with(:command, :options, holder).raises(StandardError, 'message')
    tr = cls.send(:run_thread, :command, :options, holder)
    tr.join
  end

  def test_run_and_wait_process
    holder = mock.responds_like_instance_of(cls)
    holder.expects(:before_start_handling).with(:command)
    holder.expects(:after_start_handling).with(:pid)
    cls.expects(:run_process).with(:command, :options, holder).\
      returns([:pid, StringIO.new('stdout'), StringIO.\
               new('stderr')])
    Process.expects(:wait).with(:pid)
    cls.expects(:exitstatus).returns(:exitstatus)
    holder.expects(:exit_handling).with(:exitstatus, 'stdout', 'stderr')

    cls.send(:run_and_wait_process, :command, :options, holder)
    Process.unstub
  end

  def test_exitststus
    `echo`
    assert_equal 0, cls.send(:exitstatus)
  end

  def test_run_process_in_windows
    command = mock.responds_like_instance_of(AssLauncher::Support::Shell::Command)
    command.expects(:cmd).returns(:cmd)
    command.expects(:args).returns([]).times(3)
    process_waiter = mock
    cls.expects(:windows?).returns(true)
    process_waiter.expects(:pid).returns(:pid)
    Open3.expects(:popen3).with(:cmd, '', {new_pgroup: true}).returns [:r1, :r2, :r3, process_waiter]
    assert_equal [:pid, :r2, :r3], cls.send(:run_process, command, {})
  end

  def test_run_process_in_linux_or_cygwin
    command = mock.responds_like_instance_of(AssLauncher::Support::Shell::Command)
    command.expects(:cmd).returns(:cmd)
    command.expects(:args).returns([]).times(3)
    process_waiter = mock
    cls.expects(:windows?).returns(false)
    process_waiter.expects(:pid).returns(:pid)
    Open3.expects(:popen3).with(:cmd, '', {}).returns [:r1, :r2, :r3, process_waiter]
    assert_equal [:pid, :r2, :r3], cls.send(:run_process, command, {})
  end

  def test_before_start_handling
    inst = cls.new
    inst.before_start_handling(:command)
    assert_equal :command, inst.command
  end

  def test_after_start_handling
    inst = cls.new
    inst.after_start_handling(:pid)
    assert_equal :pid, inst.pid
  end

  def test_exit_handling
    command = mock.responds_like_instance_of(AssLauncher::Support::Shell::Command)
    command.expects(:exit_handling).with(:exitstatus, :out, :err).returns(:result)
    inst = cls.new
    inst.expects(:command).returns(command)
    inst.exit_handling(:exitstatus, :out, :err)
    assert_equal :result, inst.result
  end

  def test_kill_alive
    inst = cls.new
    inst.expects(:alive?).returns(true)
    cls.expects(:cmd_exe_with_c?).returns(false)
    Process.expects(:kill).with('KILL',:pid)
    inst.expects(:pid).returns(:pid)
    assert_equal inst, inst.kill
    Process.unstub(:kill)
  end

  def test_kill_alive_fail
    inst = cls.new
    inst.expects(:alive?).returns(true)
    cls.expects(:cmd_exe_with_c?).returns(true)
    assert_raises AssLauncher::Support::Shell::ProcessHolder::KillProcessError do
      inst.kill
    end
  end

  def test_kill_dead
    Process.expects(:kill).never
    inst = cls.new
    inst.expects(:alive?).returns(false)
    assert_equal inst, inst.kill
  end

  def test_wait_alive
    thread = mock
    thread.expects(:join)
    inst = cls.new
    inst.expects(:alive?).returns(true)
    inst.expects(:thread).returns(thread)
    assert_equal inst, inst.wait
  end

  def test_wait_dead
    inst = cls.new
    inst.expects(:alive?).returns(false)
    inst.expects(:thread).never
    assert_equal inst, inst.wait
  end

  def test_alive?
    thread = mock
    thread.expects(:alive?).returns(true)
    inst = cls.new
    inst.expects(:thread).returns(thread)
    assert inst.alive?
  end

end
