# encoding: utf-8

module AssLauncher
  #
  module Enterprise
    require 'ass_launcher/enterprise/cli'
    # rubocop:disable all
    # TODO: перенести этот текст в другое место
    # fucking 1C: команда `CEATEINFOBASE` принимает фаловую строку
    # соединения в котрой путь должен быть в формате win т.е. H:\bla\bla.
    # При этом команды `ETERPRISE` и `DESIGNER` понимают и смешаный формат пути:
    # H:/bla/bla. При передаче команде `CREATEINFOBASE` некорректного пути
    # база будет создана абы где и в косоль вернется успех $?=0. Какие бывают
    # некоректные пути:
    # - (!! Похоже в v 8.3.8 устранили) H:/bla/bla - будет создана база H: где? Да прямо в корне диска H:. Вывод 1С win-xp:
    #   `Создание информационной базы ("File=H:;Locale = "ru_RU";") успешно завершено`
    # - (!! Похоже в v 8.3.8 устранили) H:/путь/котрого/нет/имябазы - будет оздана база в каталоге по умолчанию
    #   с именем InfoBase[N]. Вывод 1С win-xp:
    #   `Создание информационной базы ("File = "C:\Documents and Settings\vlv\Мои документы\InfoBase41";Locale = "ru_RU";") успешно завершено`
    #   в linux отработает корректно и попытается содать каталоги или вылитит с
    #   ошибкой ?$>0
    # - ../empty.ib - использование относительного пути в win создает базу по
    #   умолчанию как в предидущем пункте в linux создаст базу empty.ib в текущем
    #   каталоге при этом вывод 1C в linux:
    #   `Создание информационной базы ("File=../empty.ib;Locale = "en_US";") успешно завершено`
    # - H(!! Похоже в v 8.3.8 устранили):\путь\содержит-тире - в win создаст базу H:\путь\содержит вывод 1С:
    #   `Создание информационной базы ("File=H:\genm\содержит;Locale = "ru_RU";") успешно завершено`
    #   в linux отработет корректно
    # rubocop:enable all

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

      def initialize(binpath)
        @path = platform.path(binpath).realpath
        fail ArgumentError, "Is not a file `#{binpath}'" unless @path.file?
        fail ArgumentError,
             "Invalid binary #{@path.basename} for #{self.class}"\
          unless @path.basename.to_s.upcase == expects_basename.upcase
      end

      # Define version of 1C platform.
      # @note version parsed from path and may content incorrect value - not
      #  real 1C platform version see {#extract_version}. In windows,
      #  if 1C platform instaled in standart directories it work correctly.
      #  In Linux it have only 2 major
      #  digits.
      #
      # @api public
      # @return [Gem::Version]
      def version
        @version ||= extract_version(path.to_s)
      end

      # Define arch on 1C platform.
      # @note Arch of platform  actual for Linux. In windows return i386
      # @api public
      # @return [String]
      def arch
        @arch ||= extract_arch(path.to_s)
      end

      # Extract version from path
      # @note
      #  - In windows 1C V > 8.2 default install into path:
      #    +bla/1cv?/8.3.8.1502/bin/1cv8.exe+
      #  - In Linux 1V default install into path:
      #    +/opt/1C/v8.3/i386/1cv8+
      def extract_version(realpath)
        extracted = realpath.to_s.split('/')[-3]
        extracted =~ /(\d+\.\d+\.?\d*\.?\d*)/i
        extracted = (Regexp.last_match(1).to_s.split('.')\
                     + [0, 0, 0, 0])[0, 4].join('.')
        Gem::Version.new(extracted)
      end
      private :extract_version

      # Extract arch from path
      # @note (see #extract_version)
      def extract_arch(realpath)
        if linux?
          extracted = realpath.to_s.split('/')[-2]
        else
          extracted = 'i386'
        end
        extracted
      end
      private :extract_arch

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
        fail ArgumentError, "Invalid run_mode `#{run_mode}' for #{self.class}"\
          unless run_modes.include? run_mode
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
      def run_modes
        Cli.defined_modes_for(self)
      end

      # @return (see Cli::CliSpec#parameters)
      def defined_parameters(run_mode)
        cli_spec(run_mode).parameters
      end
      private :defined_parameters

      # @api public
      # @param run_mode [Symbol] run mode 1C binary.
      # @return [Cli::CliSpec]
      def cli_spec(run_mode = :enterprise)
        Cli::CliSpec.for(self, fail_if_wrong_mode(run_mode))
      end

      def build_args(run_mode, &block)
        arguments_builder = Cli::ArgumentsBuilder\
                            .new(defined_parameters(run_mode), run_mode)
        arguments_builder.instance_eval(&block)
        arguments_builder.builded_args
      end
      private :build_args

      # Wrapper for 1C thick client binary
      # @api public
      #
      # @example
      #
      #  script = cl.script(:createinfobase, 'File="path\\new.ib"')
      #  ph = script.run # this waiting until process executing
      #  ph.result.expected_assout = /\("File="path\\new.ib";.*"\)/i
      #  ph.result.verify!
      #
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
      #  args = ['/F', 'path/to/file/infobase']
      #  ph = cl.command(:designer, args).run
      #
      #  ph.wait.result.assout # => "Информационная база не обнаружена!"
      #  ph.result.exitstatus # => 0
      #
      #  # Fucking 1C: "Информационная база не обнаружена!" but exit with 0 ????
      #
      # @example
      #
      #  # Dump infobase
      #  # Directly pass parameters:
      #
      #  args = ['/F', 'path/infobase', '/DumpIB', 'dump/path/file.dt']
      #  cm = cl.command(:designer, args)
      #
      #  cm.run.wait.result.verify!
      #  #=> RunAssResult::RunAssError: Информационная база не обнаружена!
      #
      # @example
      #
      #  TODO `verify' exaples:
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
      #
      #  # Crete info base
      #
      #  ph = cl.command(:createinfobase) do
      #    connection_string "File='//host/new.ib';"
      #    _UseTemplate './application.cf'
      #    _AddInList
      #  end.run.wait
      #
      #  ph.result.verify!
      #
      #  # Check configuration
      #
      #  ph = cl.command(:designer) do
      #    _S '1c-server/infobase'
      #    _N 'admin'
      #    _P 'password'
      #    _CheckConfig do
      #      _ConfigLogIntegrity
      #      _IncorrectReferences
      #      _Extension :all
      #    end
      #  end.run.wait
      #
      #  ph.result.verify!
      #
      #  # Run enterprise Hello World
      #
      #  # Prepare external data processor 'processor.epf'
      #  # Make OnOpen form handler for main form of processor:
      #  # procedure OnOpen(Cansel)
      #  #   message("Ass listen:  " + LaunchParameter)
      #  #   exit()
      #  # endprocedure
      #
      #  ph = cl.command(:enterprise) do
      #    connection_string 'File="./infobase";Usr="admin";Pwd="password"'
      #    _Execute './processor.epf'
      #    _C 'Hello World'
      #  end.run.wait
      #
      #  ph.result.verify!
      #
      #  puts ph.result.assout #=> 'Ass listen: Hello World'
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
        def command(run_mode, args = [], **options, &block)
          args_ = args.dup
          args_.unshift mode(run_mode)
          args_ += build_args(run_mode, &block) if block_given?
          to_command(args_, options)
        end

        # Run 1C:Enterprise client as cmd or shell script.
        # @note It waiting for script
        #  execution.
        # @note It not use arguments builder and not expects of block.
        #  Arguments string make as you want
        #
        # @param run_mode (see #command)
        # @param args (see #to_script)
        # @option options (see #to_script)
        # @return (see #to_script)
        def script(run_mode, args = '', **options)
          args_ = "#{mode(run_mode)} #{args}"
          to_script(args_, options)
        end
      end

      # Wrapper for 1C thin client binary
      # @api public
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
        def command(args = [], **options, &block)
          super(:enterprise, args, options, &block)
        end

        # Run 1C:Enterprise client as cmd or shell script.
        # @note (see ThickClient#script)
        # @param args (see ThickClient#script)
        # @option options (see ThickClient#script)
        # @return (see ThickClient#script)
        def script(args = '', **options)
          super(:enterprise, args, options)
        end
      end
    end
  end
end
