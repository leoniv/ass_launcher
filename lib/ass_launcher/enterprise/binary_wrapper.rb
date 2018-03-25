# encoding: utf-8

module AssLauncher
  #
  module Enterprise
    require 'ass_launcher/enterprise/cli'

    # Class for wrapping 1C:Enterprise platform binary executables such as
    # 1cv8.exe and 1cv8c.exe.
    # Class makes it easy to juggle with the different versions of
    # 1C:Enterprise installations
    #
    # @abstract
    # @api private
    # @note (see #version)
    # @note (see #arch)
    class BinaryWrapper
      include AssLauncher::Support::Platforms
      attr_reader :path
      V64_FILES = %w{version64.dat version64.txt}
      # @api public
      X86_64 = 'x86_64'
      # @api public
      I386 = 'i386'

      def initialize(binpath)
        @path = platform.path(binpath).realpath
        fail ArgumentError, "Is not a file `#{binpath}'" unless @path.file?
        fail ArgumentError,
             "Invalid binary #{@path.basename} for #{self.class}" unless\
             @path.basename.to_s.upcase == expects_basename.upcase
      end

      # Define version of 1C platform.
      # @note In Windows version parsed from path and may
      #  content incorrect value - not
      #  real 1C platform version see {#extract_version}. For platform > 8.2
      #  if 1C platform instaled in standart directories it works correctly.
      #
      #  In linux version returns from method
      #  {AssLauncher::Support::Linux.get_pkg_version}
      #
      # @api public
      # @return [Gem::Version]
      def version
        @version ||= extract_version(path.to_s)
      end

      # Define arch on 1C platform.
      # @api public
      # @return [String] {X86_64} or {I386}
      def arch
        @arch ||= extract_arch
      end

      # True if {#arch} == {X86_64}
      # @api public
      def x86_64?
        arch == X86_64
      end

      # Extract version from path
      # @note
      #  - In windows 1C V > 8.2 default install into path:
      #    +bla/1cv?/8.3.8.1502/bin/1cv8.exe+
      #  - In Linux 1V default install into path:
      #    +/opt/1C/v8.3/i386/1cv8+
      def extract_version(realpath)
        return AssLauncher::Support::Linux.get_pkg_version(realpath) if\
          linux?
        extracted = realpath.to_s.split('/')[-3]
        Gem::Version.new v8(extracted)
      end
      private :extract_version

      def v8(extracted)
        return '8.1.0.0' if extracted =~ %r{1cv81}i
        extracted =~ /(\d+\.\d+\.?\d*\.?\d*)/i
        (Regexp.last_match(1).to_s.split('.') + [0, 0, 0, 0])[0, 4].join('.')
      end
      private :v8

      # Extract arch from path
      # @note (see #extract_version)
      def extract_arch
        if linux?
          extracted = path.to_s.split('/')[-2]
        else
          extracted =  version64? ? X86_64 : I386
        end
        extracted
      end
      private :extract_arch

      def version64?
        V64_FILES.each do |f|
          return true if version64_exist?(f)
        end
        false
      end
      private :version64?

      def version64_exist?(file)
        File.exist?(File.join(path.dirname, file))
      end
      private :version64_exist?

      # Compare wrappers on version for sortable
      # @param other [BinaryWrapper]
      # @return [Bollean]
      # @api public
      def <=>(other)
        version <=> other.version
      end

      def expects_basename
        Enterprise.binaries(self.class)
      end
      private :expects_basename

      # True if file exsists
      # @api public
      def exists?
        path.file?
      end

      # Return 2 major digits from version
      # @return [String]
      # @api public
      def major_v
        version.to_s.split('.')[0, 2].join('.')
      end

      # Convert to {AssLauncher::Support::Shell::Command} instance
      # @param args (see AssLauncher::Support::Shell::Command#initialize)
      # @option options (see AssLauncher::Support::Shell::Command#initialize)
      # @return [AssLauncher::Support::Shell::Command]
      def to_command(args = [], options = {})
        AssLauncher::Support::Shell::Command.new(path.to_s, args, options)
      end
      private :to_command

      # Convert to {AssLauncher::Support::Shell::Script} instance
      # @param args [String] string arguments for run 1C binary wrapped in
      #  +cmd.exe+ or +sh+ script like as: +'/Arg1 "Value" /Arg2 "value"'+
      # @option options (see AssLauncher::Support::Shell::Script#initialize)
      # @return [AssLauncher::Support::Shell::Script]
      def to_script(args = '', options = {})
        AssLauncher::Support::Shell::Script\
          .new("#{path.win_string.to_cmd} #{args}", options)
      end
      private :to_script

      def fail_if_wrong_mode(run_mode)
        fail ArgumentError,
          "Invalid run_mode `#{run_mode}' for #{self.class}" unless\
          run_modes.include? run_mode
        run_mode
      end
      private :fail_if_wrong_mode

      # @param run_mode [Symbol]
      #  Valid values define in the {#run_modes}
      # @raise [ArgumentError]
      # @return [String] run mode for run 1C binary
      def mode(run_mode)
        fail_if_wrong_mode(run_mode).to_s.upcase
      end
      private :mode

      # @api public
      # @return (see Cli.defined_modes_for)
      def self.run_modes
        Cli.defined_modes_for(self)
      end

      # @api public
      # @return (see Cli.defined_modes_for)
      def run_modes
        self.class.run_modes
      end

      # @api public
      # @return [Cli::CliSpec]
      def cli_spec
        @cli_spec ||= Cli::CliSpec.for(self)
      end

      def build_args(run_mode, &block)
        Cli::ArgumentsBuilder.build_args(self, run_mode, &block)
      end
      private :build_args

      # Wrapper for 1C thick client binary
      # @api public
      # @example (see #script)
      # @example (see #command)
      #
      class ThickClient < BinaryWrapper
        # (see ThinClient#accepted_connstr)
        def accepted_connstr
          [:file, :server]
        end

        # Run 1C:Enterprise client as command.
        # @note For correct pass cli parameters
        #  to 1C:Enterprise binary, you can passes block. Block will be eval in
        #  instance of {Cli::ArgumentsBuilder}. +ArgumentsBuilder+ use
        #  {Cli::CliSpec} and verify parameters and prameters values.
        #  Also you can pass arguments directly, without verify, uses +args+
        #  array.
        #
        # @note Command not wait while 1C:Enterprise execution. You can
        #  manipulate with many 1C clients runned at once.
        #
        # @param run_mode [Symbol] run mode 1C binary. It will be puts fierst
        #  parameter in +args+
        # @param args (see BinaryWrapper#to_command)
        # @option options (see BinaryWrapper#to_command)
        # @return (see #to_command)
        # @example
        #
        #  # Get 1C:Enterprise last release for 8.3.6 version:
        #
        #  cl = AssLauncher::Enterprise.thick_clients('~> 8.3.6').last
        #  raise 'Can\'t find 1C binary' if cl.nil?
        #
        # @example
        #
        #  # Run 1C:Enterprise designer
        #  # Directly pass parameters:
        #
        #  args = ['/F', 'path/to/file/infobase', '/L', 'en']
        #  ph = cl.command(:designer, args).run
        #
        #  ph.wait.result.assout # => "Infobase not found!"
        #  ph.result.exitstatus # => 0
        #
        #  # Fucking 1C: "Infobase not found!" but exit with 0 ????
        #
        # @example
        #
        #  # Dump infobase
        #  # Directly pass parameters:
        #
        #  args = ['/F', 'path/infobase', '/DumpIB', 'dump/path/file.dt', '/L',
        #         'en']
        #  cm = cl.command(:designer, args)
        #
        #  cm.run.wait.result.verify!
        #  #=> RunAssResult::RunAssError: Infobase not found!
        #
        # @example
        #
        #  # Dump infobase
        #  # Uses Cli::ArgumentsBuilder:
        #
        #  conn_str = AssLauncher::Support::ConnectionString.\
        #    new('File="//host/infobase"')
        #
        #  command = cl.command(:designer) do
        #    connection_string conn_str
        #    DumpIB './infobase.dt'
        #  end
        #  ph = command.run.wait
        #
        #  ph.result.verify!
        # @example
        #  # Open thick client and attache into debuger
        #
        #  conn_str = AssLauncher::Support::ConnectionString.\
        #    new('srvr="localhost"; ref="infobase"')
        #
        #  command = cl.command(:enterprise) do
        #    connection_string conn_str
        #    debug
        #    debuggerUrl 'localhost'
        #  end
        #  ph = command.run.wait # Fucking 1C: If infobase not exists
        #  #will be opened GUI window with info similar 'Inforamation base
        #  #not found. Create new?" and exit whith status 0
        #
        #  #Fucking 1C:
        #  #USES GUI DIALOG FOR ERROR REPORTING WHEN RUN IN NO GUI MODE
        def command(run_mode, args = [], **options, &block)
          args_ = args.dup
          args_.unshift mode(run_mode)
          args_ += build_args(run_mode, &block) if block_given?
          verify_createinfobase_param_order! args_ if\
            run_mode == :createinfobase
          to_command(args_, options)
        end

        # Fucking 1C not check CLI parameter
        # In create infobase mode create default infobase in user profile
        # directory if the first parameter is not connection string!!!
        def verify_createinfobase_param_order!(args)
          cs = parse_cs args[1]
          fail ArgumentError, ':createinfobase expects file or server'\
          " connection string in first argument but given `#{args[1]}'" unless\
          good_cs?(cs)
          args
        end
        private :verify_createinfobase_param_order!

        def good_cs?(cs)
          return false unless cs
          cs.is?(:file) || cs.is?(:server)
        end
        private :good_cs?

        def parse_cs(string)
          AssLauncher::Support::ConnectionString\
            .new(string.to_s.tr('\'', '"'))
        rescue AssLauncher::Support::ConnectionString::ParseError
          nil
        end
        private :parse_cs

        # Run 1C:Enterprise client as cmd or shell script.
        # @note It waiting for script
        #  execution.
        # @note It not use arguments builder and not expects of block.
        #  Arguments string make as you want
        #
        # @param run_mode (see #command)
        # @param args (see #to_script)
        # @option options (see #to_script)
        # @example
        #
        #  cl = AssLauncher::Enterprise.thick_clients('~> 8.3.6').last
        #  script = cl.script(:createinfobase, 'File="path\\new.ib"')
        #  ph = script.run # this waiting until process executing
        #  ph.result.expected_assout = /\("File="path\\new.ib";.*"\)/i
        #  ph.result.verify!
        #
        # @return (see #to_script)
        def script(run_mode, args = '', **options)
          args_ = "#{mode(run_mode)} #{args}"
          to_script(args_, options)
        end
      end

      # Wrapper for 1C thin client binary
      # @api public
      # @example (see #script)
      # @example (see #command)
      #
      class ThinClient < ThickClient
        # Define type of connection_string
        # suitable for 1C binary
        # @return [Array<Symbol>]
        def accepted_connstr
          [:file, :server, :http]
        end

        # Run 1C:Enterprise client as command.
        # @note (see ThickClient#command)
        # @param args (see ThickClient#command)
        # @option options (see ThickClient#command)
        # @return (see ThickClient#command)
        # @example
        #
        #  cl = AssLauncher::Enterprise.thin_clients('~> 8.3.6').last
        #  args = ['/F', 'path/to/file/infobase']
        #  ph = cl.command(args).run # Fucking 1C: If infobase not exists
        #  #will be opened GUI window with error info similar 'Inforamation base
        #  #not found"
        #
        #  ph.wait # => waiting wile execiting
        #  ph.result.exitstatus # => 0
        #
        #  # Uses Cli::ArgumentsBuilder:
        #
        #  conn_str = AssLauncher::Support::ConnectionString.\
        #    new('File="//host/infobase"')
        #
        #  command = cl.command do
        #    connection_string conn_str
        #    debug
        #    debuggerUrl 'localhost'
        #  end
        #  ph = command.run.wait # Fucking 1C: If infobase not exists
        #  #will be opened GUI window with error info similar 'Inforamation base
        #  #not found"
        #

        def command(args = [], **options, &block)
          super(:enterprise, args, options, &block)
        end

        # Run 1C:Enterprise client as cmd or shell script.
        # @note (see ThickClient#script)
        # @param args (see ThickClient#script)
        # @option options (see ThickClient#script)
        # @return (see ThickClient#script)
        # @example
        #  cl = AssLauncher::Enterprise.thin_clients('~> 8.3.6').last
        #  script = cl.script('File="path\\new.ib"')
        #  ph = script.run # this waiting until process executing
        #  # Fucking 1C: if infobase not exists will be opened GUI window
        #  #for infobase choice!
        def script(args = '', **options)
          super(:enterprise, args, options)
        end
      end
    end
  end
end
