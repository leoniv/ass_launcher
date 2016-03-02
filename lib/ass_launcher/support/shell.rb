# encoding: utf-8

# Monkey patch for [String]
class String
  require 'shellwords'
  def to_cmd
    if AssLauncher::Support::Platforms.windows?\
        || AssLauncher::Support::Platforms.cygwin?
      "\"#{self}\""
    else
      escape
    end
  end

  def escape
    Shellwords.escape self
  end
end

module AssLauncher
  class << self
    def config
      @config ||= Configuration.new
    end
  end

  def self.configure
    yield(config)
  end

  class Configuration
    attr_accessor :logger

    def initialize
      @logger = Loggining.default_logger
    end

    def logger=(l)
      fail ArgumentError, 'Logger may be valid logger' if l.nil?
      @logger = l
    end
  end
  # Loggining mixin
  module Loggining
    require 'logger'

    DEFAULT_LEVEL = Logger::Severity::UNKNOWN

    def self.included(k)
      k.extend(self)
    end

    def logger
      AssLauncher.config.logger
    end

    # @api private
    def self.default_logger
      l = Logger.new($stderr)
      l.level = DEFAULT_LEVEL
      l
    end
  end
  module Support
    # Shell utils
    module Shell
      # TODO: delete it see todo in platform #cygpath func
      class RunError < StandardError; end
      require 'methadone'
      require 'tempfile'
      include Loggining
      include Methadone::SH
      extend Support::Platforms

      # @note Fuckin 1C not work with stdout and stderr
      #  For out 1C use /OUT"file" parameter and write message into. Message
      #  encoding 'cp1251' for windows and 'utf-8' for Linux
      # This method run 1C binaryes whit /DisableStartupDialogs,
      # /DisableStartupMessages and /OUT parameter, read message from /OUT
      # @param cmd (see #dirtyrun_ass)
      # @param options [Hash]
      #  - :out_encoding - encoding expected for text in /OUT file
      #  - :expected_assout [Regexp] - for validate /OUT text see
      #  {RunAssResult#initialize}
      # @return (see #dirtyrun_ass)
      def run_ass(cmd, options = {})
        of = AssOutFile.new(options[:out_encoding])
        cmd_ = "#{cmd} /OUT\"#{of}\" /DisableStartupDialogs "\
          '/DisableStartupMessages'
        result = dirtyrun_ass(cmd_)
        result.send(:expected_assout=, options[:expected_assout])
        result.send(:assout=, of.read)
        loggining_assout result
        result
      end
      module_function :run_ass

      # rubocop:disable Metrics/AbcSize
      def loggining_assout(result)
        if result.expected_assout?
          logger.debug "expects ass output: '#{result.expected_assout}'"\
            unless result.expected_assout.nil?
          loggining_assout_output result
        else
          logger.error 'Unexpected ass out'
          logger.warn "expects ass output: '#{result.expected_assout}'"
          logger.warn "ass output: #{result.assout}"
        end
      end
      # rubocop:enable Metrics/AbcSize
      module_function :loggining_assout
      private :loggining_assout

      def loggining_assout_output(result)
        if result.success?
          logger.debug "ass output: #{result.assout}"\
            unless result.assout.to_s.empty?
        else
          logger.warn "ass output: #{result.assout}"\
            unless result.assout.to_s.empty?
        end
      end
      module_function :loggining_assout_output
      private :loggining_assout_output

      # Run 1C platform.
      # @param cmd [String]
      # @return [RunAssResult]
      def dirtyrun_ass(cmd)
        begin
          _stdout, stderr, status = cmd_string(cmd).execute
          result = RunAssResult.new(cmd, stderr, status.exitstatus)
        rescue *exception_meaning_command_not_found => e
          result = RunAssResult.new(cmd, e.message, 127)
        end
        loggining_runass result
        result
      end
      module_function :dirtyrun_ass

      def loggining_runass(result)
        if result.success?
          logger.debug 'Executing ass success'
        else
          logger.error "Executing ass '#{result.cmd}'"
          logger.warn "stderr output: #{result.out}"\
            unless result.out.empty?
        end
      end
      module_function :loggining_runass
      private :loggining_runass

      def cmd_string(cmd)
        if windows? || cygwin?
          CmdScript.new(cmd)
        else
          CmdString.new(cmd)
        end
      end
      module_function :cmd_string
      private :cmd_string

      # @private
      class CmdString
        include AssLauncher::Loggining
        attr_reader :run_ass_str, :command
        def initialize(run_ass_str)
          @run_ass_str = run_ass_str
          @command = run_ass_str
        end

        def execution_strategy
          AssLauncher::Support::Shell.send(:execution_strategy)
        end

        def execute
          logger.debug("Executing command: '#{command}'")
          execution_strategy.run_command(command)
        end

        def to_s
          command
        end
      end

      # @private
      class CmdScript < CmdString
        include Support::Platforms
        attr_reader :file, :path
        def initialize(cmd)
          super
          @file = Tempfile.new(%w( run_ass_script .cmd ))
          @file.open
          @file.write(encode_cmd(cmd))
          @file.close
          @path = platform.path(@file.path)
        end

        def encode_cmd(cmd)
          if cygwin? || windows?
            # TODO:have to detect current win cmd encoding. cp866 - may be wrong
            begin
              return cmd.encode('cp866', 'utf-8')
            rescue Exception => e
              logger.error "Encode cmd #{e.class}: #{e.message}"
              logger.warn "cmd: #{cmd}"
              raise e
            end
          end
          cmd
        end

        def command
          if cygwin? || windows?
            "cmd /C \"#{path.win_string}\""
          else
            "sh #{path.to_s.escape}"
          end
        end

        def execute
          logger.debug("Executed script text: '#{run_ass_str}'")
          out, err, status = super
          if cygwin?
            # TODO:have to detect current win cmd encoding. cp866 - may be wrong
            begin
              out.encode!('utf-8', 'cp866')
              err.encode!('utf-8', 'cp866')
            rescue Exception => e
              logger.error "Encode out #{e.class}: #{e.message}"
            end
          end
          [out, err, status]
        ensure
          @file.unlink
        end
      end

      class RunAssResult
        class UnexpectedAssOut < StandardError; end
        class RunAssError < StandardError; end
        attr_reader :cmd, :out, :assout, :exitstatus, :expected_assout
        attr_writer :assout
        private :assout=
        def initialize(cmd, out, exitstatus)
          @cmd = cmd
          @out = out
          @exitstatus = exitstatus
          @assout = ''
        end

        # Verivfy of result and raises unless {#success?}
        # @raise [UnexpectedAssOut] - exitstatus == 0 but taken unexpected
        #  assout {!#expected_assout?}
        # @raise [RunAssError] - if other errors taken
        def verify!
          fail UnexpectedAssOut, cut_assout unless expected_assout?
          fail RunAssError, "#{out}#{cut_assout}" unless success?
          self
        end

        def cut_assout
          return assout if assout.size <= 80
          "#{assout[0, 80]}..."
        end
        private :cut_assout

        def success?
          exitstatus == 0 && expected_assout?
        end

        def expected_assout=(exp)
          return if exp.nil?
          fail ArgumentError unless exp.is_a? Regexp
          @expected_assout = exp
        end
        private :expected_assout=

        # @note Sometimes 1C does what we not expects. For example, we ask
        #  to create InfoBase File="tmp\tmp.ib" however 1C make files of
        #  infobase in root of 'tmp\' directory and exits with status 0. In this
        #  case we have to check assout for answer executed success? or not.
        # Checkin {#assout} string
        # If existstatus != 0 checking assout value skiped and return true
        # It work when exitstatus == 0 but taken unexpected assout
        # @return [Boolean]
        def expected_assout?
          return true if expected_assout.nil?
          return true if exitstatus != 0
          ! (expected_assout =~ assout).nil?
        end
      end

      # @api private
      class AssOutFile
        include Support::Platforms
        attr_reader :file, :path, :encoding
        def initialize(encoding = nil)
          @file = Tempfile.new('ass_out')
          @file.close
          @path = platform.path(@file.path)
          @encoding = encoding || Encoding::CP1251
        end

        def to_s
          @path.to_s
        end

        def read
          begin
            @file.open
            s = @file.read
            s.encode! Encoding::UTF_8, encoding unless linux?
          ensure
            @file.close
            @file.unlink
          end
          s.to_s
        end
      end
    end
  end
end
