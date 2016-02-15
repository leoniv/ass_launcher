# encoding: utf-8

# Monkey patch for [String]
class String
  require 'shellwords'
  def escape
    if AssLauncher::Support::Platforms.windows?
      "\"#{self}\""
    else
      Shellwords.escape self
    end
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
    module Shell
      require 'methadone'
      require 'tempfile'
      include Loggining
      include Methadone::SH

      # @note Fuckin 1C not work with stdout and stderr
      #  For out 1C use /OUT"file" parameter and write message into. Message
      #  encoding 'cp1251' for windows and 'utf-8' for Linux
      # This method run 1C binaryes whit /OUT parameter, read message from /OUT
      # and yeld exit status and readed message into block. Return exit code
      # @param cmd (see dirtyrun)
      # @param options [Hash]
      # @return (see dirtyrun_ass)
      def run_ass(cmd, options = {})
        of = AssOutFile.new(options[:out_encoding])
        cmd_ = "#{cmd} /OUT\"#{of}\" /DisableStartupDialogs "\
          "/DisableStartupMessages"
        result = dirtyrun_ass(cmd_)
        result.send(:expected_assout=, options[:expected_assout])
        result.send(:assout=, of.read)
        if result.success?
          logger.debug "ass output: #{result.assout}" unless result.assout.empty?
        else
          logger.error "Unexpected ass out" unless result.expected_assout?
          logger.warn "expects ass output: '#{result.expected_assout}'"\
            unless result.expected_assout?
          logger.warn "ass output: #{result.assout}" unless result.assout.empty?
        end
        result
      end
      module_function :run_ass

      # Run 1C platform.
      # @param cmd [String]
      # @return [RunAssResult]
      def dirtyrun_ass(cmd)
        logger.debug("Executing ass '#{cmd}'")
        begin
          stdout, stderr, status = execution_strategy.run_command(cmd)
          result = RunAssResult.new(cmd, stderr, status.exitstatus)
        rescue *exception_meaning_command_not_found => e
          result = RunAssResult.new(cmd, e.message, 127)
        end
        if result.success?
          logger.debug "Executing ass success"
        else
          logger.error "Executing ass '#{cmd}'"
          logger.warn "stderr output of '#{cmd}': #{result.out}"\
            unless result.out.empty?
        end
        result
      end
      module_function :dirtyrun_ass

      class RunAssResult
        class UnexpectedAssOut < StandardError; end
        class RunAssError < StandardError; end
        attr_reader :cmd, :out, :assout, :exitstatus, :expected_assout
        def initialize(cmd, out, exitstatus)
          @cmd = cmd
          @out = out
          @exitstatus = exitstatus
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
          return @assout if @assout.size <= 80
          "#{@assout[0,80]} ..."
        end
        private :cut_assout

        def success?
          exitstatus == 0 && expected_assout?
        end

        def assout=(s)
          @assout = s
        end
        private :assout=

        def expected_assout=(exp)
          return if exp.nil?
          fail ArgumentError unless exp.is_a? Regexp
          @expected_assout = exp
        end
        private :expected_assout=

        # @note Sometimes 1С does what we not expects. For example, we ask
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
          !! (expected_assout =~ assout)
        end

      end

      class AssOutFile
        include Support::Platforms
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
            s.encode! Encoding::UTF_8, @encoding unless linux?
          ensure
            @file.close
          end
          s.to_s
        end

        def finalize
          @file.unlink
        end
      end
    end
  end
end
