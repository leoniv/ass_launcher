# encoding: utf-8
module AssLauncher
  module Support
    module Shell
      # Class for runned subprocess and controlling him
      # Process run with command in thread. Thread waiting for process exit
      # and call exit_handling for command object see param command of {::run}
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
      # WARNIG!!! not forgot kill of threads created and handled of
      # ProcessHolder
      #
      # @note For run command used popen3 whith command_string and *args.
      # It not shell running. If command.args.size == 0 in command.args array
      # will be pushed one empty string.
      # For more info see Process.spawn documentation
      class ProcessHolder
        require 'open3'
        require 'ass_launcher/support/platforms'
        extend Support::Platforms
        class KillProcessError < StandardError; end
        class RunProcessError < StandardError; end
        attr_reader :pid, :result, :command
        attr_accessor :thread
        private :thread=

        # Hold of created thrades
        # @return [Arry<Thread>]
        def self.threads_list
          @@threads_list ||= []
        end

        # Hold of created instaces
        # @return [Arry<ProcessHolder>]
        def self.process_list
          @@process_slist ||= []
        end

        # @note 'cmd /K command` not exit when exit command. Thread hangup
        def self.cmd_exe_with_k?(command)
          shell_str = "#{command.cmd} #{command.args.join(' ')}"
          ! (shell_str =~ %r{(?<=\W|\A)cmd(.exe)?\s*(\/K)}i).nil?
        end

        # @note 'cmd /C command` not kill command when cmd killed
        def self.cmd_exe_with_c?(command)
          shell_str = "#{command.cmd} #{command.args.join(' ')}"
          ! (shell_str =~ %r{(?<=\W|\A)cmd(.exe)?\s*(\/C)}i).nil?
        end

        # Run command subprocess in new Thread and return instace for process
        # controlling
        # Thread wait process and handling process exit wihth {#exit_handling}
        # @param command [Shell::Command] - command runned in subprocess
        # @param options [Hash] - optios for Process.spawn
        # @return [ProcessHolder]
        # @note (see ProcessHolder)
        # @raise [RunProcessError] if command is cmd.exe with /K key see
        # {::cmd_exe_with_k?}
        def self.run(command, options = {})
          fail RunProcessError, 'Forbidden run cmd.exe with /K key'\
            if cmd_exe_with_k? command
          h = ProcessHolder.new
          h.send(:thread=, run_thread(command, options, h))
          process_list << h
          h
        end

        # Run new thread
        def self.run_thread(command, options, h)
          tr = Thread.new do
            begin
              run_and_wait_process command, options, h
            rescue StandardError => e
              h.exit_handling(1, '', "#{e.class} #{e.message}")
            end
          end
          threads_list << tr
          tr
        end
        private_class_method :run_thread

        def self.run_and_wait_process(command, options, h)
          h.before_start_handling(command)
          pid, stdout, stderr = run_process(command, options, h)
          h.after_start_handling(pid)
          Process.wait pid
          h.exit_handling(exitstatus, stdout.read, stderr.read)
        end
        private_class_method :run_and_wait_process

        def self.exitstatus
          $?.exitstatus
        end
        private_class_method :exitstatus

        # Run new process
        def self.run_process(command, options = {})
          command.args << '' if command.args.size == 0
          options[:new_pgroup] = true if windows?
          _r1, r2, r3, pw = Open3.popen3 command.cmd, *command.args, options
          [pw.pid, r2, r3]
        end
        private_class_method :run_process

        # @api private
        def before_start_handling(command)
          @command = command
        end

        # @api private
        def after_start_handling(pid)
          @pid = pid
        end

        # @api private
        def exit_handling(exitstatus, out, err)
          @result = command.exit_handling(exitstatus, out, err)
        end

        # Kill the process
        # @return [ProcessHolder] - self
        # @note WARNIG! for command runned as cmd /C commnd can't get pid of
        #  command process. In this case error raised
        # @raise [KillProcessError] if command is cmd.exe with /C key see
        # {::cmd_exe_with_c?}
        def kill
          return self unless alive?
          fail KillProcessError, 'Can\'t kill subprocess runned in cmd.exe '\
            'on the windows machine' if self.class.cmd_exe_with_c? command
          Process.kill('KILL', pid)
          self
        end

        # Wait for thread exit
        # @return [ProcessHolder] self
        def wait
          return self unless alive?
          thread.join
          self
        end

        # True if thread alive
        def alive?
          thread.alive?
        end
      end # ProcessHolder
    end # Shell
  end # Support
end # AssLauncher
