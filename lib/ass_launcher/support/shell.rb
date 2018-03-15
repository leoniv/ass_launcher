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

#
module AssLauncher
  class << self
    def config
      @config ||= Configuration.new
    end
  end

  def self.configure
    yield(config)
  end

  # Configuration for {AssLauncher}
  class Configuration
    attr_reader :logger

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
    # Shell utils for run 1C:Enterprise binary
    module Shell
      # TODO: delete it see todo in platform #cygpath func
      class RunError < StandardError; end
      require 'methadone'
      require 'tempfile'
      require 'ass_launcher/support/shell/process_holder'
      include Loggining
      include Methadone::SH
      extend Support::Platforms

      # Command running directly as:
      # popen3(command.cmd, *command.args, options)
      #
      # @note What reason for it? Reason for it:
      #
      #  Fucking 1C binary often unexpected parse cmd arguments if run in
      #  shell like `1c.exe arguments`. For correction this invented two way run
      #  1C binary: as command see {Shell::Command} or as script
      #  see {Shell::Script}. If run 1C as command we can control executing
      #  process wait exit or kill 1C binary process. If run 1C as script 1C
      #  more correctly parse arguments but we can't kill subprosess running
      #  in cmd.exe
      #
      # @note On default use silient execute 1C binary whit
      #  /DisableStartupDialogs,
      #  /DisableStartupMessages parameters and capture 1C output /OUT
      #  parameter. Read  message from /OUT when 1C binary process exit and
      #  build instnce of RunAssResult.
      #
      # @note (see AssOutFile)
      # @api private
      class Command
        attr_reader :cmd, :args, :ass_out_file, :options
        attr_accessor :process_holder
        private :process_holder=
        private :ass_out_file
        DEFAULT_OPTIONS = { silent_mode: true,
                            capture_assout: true,
                            disable_auto_check_version: true}.freeze
        # @param cmd [String] path to 1C binary
        # @param args [Array] arguments for 1C binary
        # @option options [String] :assout_encoding encoding for assoutput file.
        #  Default 'cp1251'
        # @option options [Boolean] :capture_assout capture assoutput.
        #  Default true
        # @option options [Boolean]:silent_mode run 1C with
        #  /DisableStartupDialogs and /DisableStartupMessages parameters.
        #  Default true
        # @raise [ArgumentError] when +capture_assout: true+ and +args+
        #  include +/OUT+ parameter
        # @api private
        def initialize(cmd, args = [], options = {})
          @options = DEFAULT_OPTIONS.merge(options).freeze
          @cmd = cmd
          @args = args
          validate_args
          @args += (_silent_mode + _disable_auto_check_version)
          @ass_out_file = _ass_out_file
        end

        def validate_args
          fail ArgumentError,
               'Duplicate of /OUT parameter.'\
               ' Delete /OUT from args or set option capture_assout: false' if\
                 duplicate_param_out?
        end
        private :validate_args

        def duplicate_param_out?
          capture_assout? && args_include?(%r{\A\/OUT\z}i)
        end
        private :duplicate_param_out?

        def args_include?(regex)
          args.grep(regex).size > 0
        end
        private :args_include?

        def capture_assout?
          options[:capture_assout]
        end

        # @return [true] if command was already running
        def running?
          !process_holder.nil?
        end

        # Run command
        # @param options [Hash] options for Process.spawn
        # @return [ProcessHolder]
        def run(options = {})
          return process_holder if running?
          ProcessHolder.run(self, options)
        end

        def _disable_auto_check_version
          if options[:disable_auto_check_version]
            ['/AppAutoCheckVersion-', '']
          else
            []
          end
        end
        private :_disable_auto_check_version

        def _silent_mode
          if options[:silent_mode]
            ['/DisableStartupDialogs', '',
             '/DisableStartupMessages', '']
          else
            []
          end
        end
        private :_silent_mode

        def _out_ass_argument(out_file)
          @args += ['/OUT', out_file.to_s]
          out_file
        end
        private :_out_ass_argument

        def _ass_out_file
          if capture_assout?
            out_file = AssOutFile.new(options[:assout_encoding])
            _out_ass_argument out_file
          else
            StringIO.new
          end
        end
        private :_ass_out_file

        def to_s
          "#{cmd} #{args.join(' ')}"
        end

        def exit_handling(exitstatus, out, err)
          RunAssResult.new(exitstatus, encode_out(out),
                           encode_out(err), ass_out_file.read)
        end

        # @todo It's stub returns +out+ directly
        #   but may be require encoding out
        #   encoding must executed in try block
        def encode_out(out)
          out
        end
        private :encode_out
      end

      # class {Script} wraping cmd string in to script tempfile and  running as:
      # popen3('cmd.exe', '/C', 'tempfile' in cygwin or windows
      # or popen3('sh', 'tempfile') in linux
      #
      # @note (see Command)
      # @api private
      class Script < Command
        include Support::Platforms
        # @param cmd [String] cmd string for executing as cmd.exe or sh script
        # @option (see Command#initialize)
        def initialize(cmd, options = {})
          super cmd, [], options
        end

        def make_script
          @file = Tempfile.new(%w( run_ass_script .cmd ))
          @file.open
          @file.write(encode)
          @file.close
          platform.path(@file.path)
        end
        private :make_script

        # @note used @args variable for reason!
        #  In class {Script} methods {Script#cmd} and
        #  {Script#args} returns command and args for run
        #  script in sh or cmd.exe but @rgs varible use in {#to_s} for
        #  generate script content
        #  script
        def _out_ass_argument(out_file)
          @args += ['/OUT', "\"#{out_file}\""]
          out_file
        end
        private :_out_ass_argument

        def encode
          if cygwin_or_windows?
            # TODO: need to detect current win cmd encoding cp866 - may be wrong
            return to_s.encode('cp866', 'utf-8')
          end
          to_s
        end
        private :encode

        # @note used @cmd and @args variable for reason!
        #  In class {Script} methods {Script#cmd} and
        #  {Script#args} returns command and args for run
        #  script in sh or cmd.exe but {#to_s} return content for
        #  script
        def to_s
          "#{@cmd} #{@args.join(' ')}"
        end

        def cygwin_or_windows?
          cygwin? || windows?
        end
        private :cygwin_or_windows?

        # Returm shell binary 'cmd.exe' or 'sh'
        # @return [String]
        def cmd
          if cygwin_or_windows?
            'cmd.exe'
          else
            'sh'
          end
        end

        # Return args for run shell script
        # @return [Array]
        def args
          if cygwin_or_windows?
            ['/C', make_script.win_string]
          else
            [make_script.to_s]
          end.freeze
        end

        def encode_out(out)
          # TODO: need to detect current win cmd encoding cp866 - may be wrong
          begin
            out.encode!('utf-8', 'cp866') if cygwin_or_windows?
          rescue EncodingError => e
            return "#{e.class}: #{out}"
          end
          out
        end
        private :encode_out

        # Run script. Script wait process exit
        # @param options [Hash] options for Process.spawn
        # @return [ProcessHolder]
        def run(options = {})
          ph = super
          ph.wait
        end
      end

      # Contain result for execute 1C binary
      # see {ProcessHolder#result}
      # @api private
      class RunAssResult
        class UnexpectedAssOut < StandardError; end
        class RunAssError < StandardError; end
        attr_reader :out, :assout, :exitstatus, :err
        attr_reader :expected_assout
        def initialize(exitstatus, out, err, assout)
          @err = err
          @out = out
          @exitstatus = exitstatus
          @assout = assout
        end

        # Verivfy of result and raises unless {#success?}
        # @raise [UnexpectedAssOut] - exitstatus == 0 but taken unexpected
        #  assout {!#expected_assout?}
        # @raise [RunAssError] - if other errors taken
        # @api public
        def verify!
          fail UnexpectedAssOut, cut_assout unless expected_assout?
          fail RunAssError, "#{err}#{cut_assout}" unless success?
          self
        end

        CUT_ASSOUT_LENGTH = 640

        def cut_assout
          return assout if assout.size <= CUT_ASSOUT_LENGTH
          "#{assout[0, CUT_ASSOUT_LENGTH].strip}..."
        end
        private :cut_assout

        # @api public
        def success?
          exitstatus == 0 && expected_assout?
        end

        # Set regex for verify assout
        # @note (see #expected_assout?)
        # @param exp [nil, Regexp]
        # @raise [ArgumentError] when bad expresion given
        # @api public
        def expected_assout=(exp)
          return if exp.nil?
          fail ArgumentError unless exp.is_a? Regexp
          @expected_assout = exp
        end

        # @note Sometimes 1C does what we not expects. For example, we ask
        #  to create InfoBase File="tmp\tmp.ib" however 1C make files of
        #  infobase in root of 'tmp\' directory and exits with status 0. In this
        #  case we have to check assout for answer executed success? or not.
        # Checkin {#assout} string
        # If existstatus != 0 checking assout value skiped and return true
        # It work when exitstatus == 0 but taken unexpected assout
        # @return [Boolean]
        # @api public
        def expected_assout?
          return true if expected_assout.nil?
          return true if exitstatus != 0
          ! (expected_assout =~ assout).nil?
        end
      end

      # Hold, read and encode 1C output
      #
      # @note Fucking 1C not work with stdout and stderr
      #  For out 1C use /OUT"file" parameter and write message into. Message
      #  encoding 'cp1251' for windows and 'utf-8' for Linux
      # @api private
      class AssOutFile
        include Support::Platforms
        attr_reader :file, :path, :encoding
        def initialize(encoding = nil)
          @file = Tempfile.new('ass_out')
          @file.close
          @path = platform.path(@file.path)
          @encoding = encoding || detect_ass_encoding
        end

        # @todo It's stub returns the CP1251 encoding
        #   but requires to detect 1C out encoding automatically
        def detect_ass_encoding
          Encoding::CP1251
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
            try_unlink
          end
          s.to_s
        end

        # File can be busy
        def try_unlink
          @file.unlink if @file
        rescue Errno::EBUSY
          # NOP
        end
      end
    end
  end
end
