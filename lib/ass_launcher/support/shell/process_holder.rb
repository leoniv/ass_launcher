# encoding: utf-8
module AssLauncher
  module Support
    module Shell
      # Class for running {Command} in subprocess and controlling
      # him.
      # Process run command in the thread. Thread waiting for process exit
      # and call {Command#exit_handling}
      # @example
      #  # Run command and witing for exit
      #  ph = ProcessHolder.run(command, options)
      #
      #  result = ph.wait.result
      #  raise 'bang!' unless result.sucsess?
      #
      #  # Run command and kill process when nidet
      #
      #  ph = ProcessHolder.run(command, options)
      #
      #  sleep 10 # for wakeup command
      #
      #  if ! ph.alive?
      #    raise 'command onexpected exit'
      #  end
      #
      #  # doing something
      #
      #  ph.kill
      #
      #  # run and wait command
      #
      #  ph = ProcessHolder.run(command, options).wait
      #
      #  raise if ph.result.success?
      #
      #
      # @note WARNIG!!! not forgot kill of threads created and handled of
      #  ProcessHolder
      #
      # @note For run command used popen3 whith command_string and *args.
      #  It not shell running. If command.args.size == 0 in command.args array
      #  will be pushed one empty string.
      #  For more info see Process.spawn documentation
      # @api private
      class ProcessHolder
        require 'open3'
        require 'ass_launcher/support/platforms'
        include Support::Platforms
        class KillProcessError < StandardError; end
        class RunProcessError < StandardError; end
        # @api public
        # @return [Fixnum] pid of runned process
        attr_reader :pid

        # @api public
        # @return [RunAssResult] result of execution command
        attr_reader :result

        # @api public
        # @return [Command, Script] command runned in process
        attr_reader :command

        # @api private
        # @return [Thread] thread waiting for process
        attr_reader :thread

        # @api private
        attr_reader :options, :popen3_thread

        Thread.abort_on_exception = true

        # Keep of created instaces
        # @return [Arry<ProcessHolder>]
        # @api public
        def self.process_list
          @@process_slist ||= []
        end

        # @note 'cmd /K command` not exit when exit command. Thread hangup
        # @api private
        def self.cmd_exe_with_k?(command)
          shell_str = "#{command.cmd} #{command.args.join(' ')}"
          ! (shell_str =~ %r{(?<=\W|\A)cmd(.exe)?\s*(\/K)}i).nil?
        end

        # @note 'cmd /C command` not kill command when cmd killed
        # @api private
        def self.cmd_exe_with_c?(command)
          shell_str = "#{command.cmd} #{command.args.join(' ')}"
          ! (shell_str =~ %r{(?<=\W|\A)cmd(.exe)?\s*(\/C)}i).nil?
        end

        # Run command subprocess in new Thread and return instace for process
        # controlling
        # Thread wait process and handling process exit wihth
        # {Command#exit_handling}
        # @param command [Command, Script] command runned in subprocess
        # @param options [Hash] options for +Process.spawn+
        # @return [ProcessHolder] instance with runned command
        # @note (see ProcessHolder)
        # @raise [RunProcessError] if command is cmd.exe with /K key see
        #  {cmd_exe_with_k?}
        # @api public
        def self.run(command, options = {})
          fail RunProcessError, 'Forbidden run cmd.exe with /K key'\
            if cmd_exe_with_k? command
          h = ProcessHolder.new(command, options)
          process_list << h
          h.run
        end

        # @param (see run)
        def initialize(command, options = {})
          @command = command
          @options = options
          options[:new_pgroup] = true if windows?
        end

        # @return [self]
        def run
          @popen3_thread, stdout, stderr = run_process
          @pid = @popen3_thread.pid
          @thread = wait_process_in_thread(stdout, stderr)
          self
        end

        def wait_process_in_thread(stdout, stderr)
          Thread.new do
            popen3_thread.join
            begin
              @result = command.exit_handling(exitstatus,\
                                              stdout.read,\
                                              stderr.read)
            rescue StandardError => e
              @result = e
            end
          end
        end
        private :wait_process_in_thread

        def exitstatus
          popen3_thread.value.to_i
        end
        private :exitstatus

        # Run new process
        def run_process
          command.args << '' if command.args.size == 0
          _r1, r2, r3, thread = Open3.popen3 command.cmd, *command.args, options
          [thread, r2, r3]
        end
        private :run_process

        # Kill the process
        # @return [self]
        # @note WARNIG! for command runned as cmd /C commnd can't get pid of
        #  command process. In this case error raised
        # @raise [KillProcessError] if command is cmd.exe with /C key see
        #  {cmd_exe_with_c?}
        # @api public
        def kill
          return self unless alive?
          fail KillProcessError, 'Can\'t kill subprocess runned in cmd.exe '\
            'on the windows machine' if self.class.cmd_exe_with_c? command
          Process.kill('KILL', pid)
          wait
        end

        # Wait for thread exit
        # @return [self]
        # @api public
        def wait
          return self unless alive?
          thread.join
          self
        end

        # True if thread alive
        # @api public
        def alive?
          thread.alive?
        end
      end # ProcessHolder
    end # Shell
  end # Support
end # AssLauncher
