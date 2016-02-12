# encoding: utf-8

# Monkey patch for [String]
class String
  require 'shellwords'
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
      # @return [Fixnum] exit code
      def run_ass(cmd, options = {})
        of = AssOutFile.new(options[:out_encoding])
        cmd_ = "#{cmd} /OUT\"#{of}\" /DisableStartupDialogs"
        stdout_ = ''
        stderr_ = ''
        exitstatus = sh(cmd_, options) do |stdout, stderr|
          stdout_ = stdout
          stderr_ = stderr
        end
        assout = of.read
        if exitstatus == 0
          logger.debug "ass output: #{assout}" unless assout.empty?
        else
          logger.warn "ass output: #{assout}" unless assout.empty?
        end
        RunAssResult.new(cmd_, stdout_, stderr_, assout, exitstatus)
      end
      module_function :run_ass

      class RunAssResult
        attr_reader :cmd, :stdout, :stderr, :assout, :exitstatus
        def initialize(cmd, stdout, stderr, assout, exitstatus)
          @cmd = cmd
          @stdout = stdout
          @stderr = stderr
          @assout = assout
          @exitstatus = exitstatus
        end

        def success?
          @exitstatus == 0
        end
      end

      # @note (see run_ass)
      # @raise fixme
      def run_ass!(cmd, options = {}, &block)
        _ass_out = ''

        raise 'FIXME'
      end
      module_function :run_ass!

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
