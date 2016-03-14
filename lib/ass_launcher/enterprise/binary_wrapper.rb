# encoding: utf-8

module AssLauncher
  module Enterprise
    # TODO: перенести этот текст в другое место
    # fucking 1C: команда `CEATEINFOBASE` принимает фаловую строку
    # соединения в котрой путь должен быть в формате win т.е. H:\bla\bla.
    # При этом команды `ETERPRISE` и `DESIGNER` понимают и смешаный формат пути:
    # H:/bla/bla. При передаче команде `CREATEINFOBASE` некорректного пути
    # база будет создана абы где и в косоль вернется успех $?=0. Какие бывают
    # некоректные пути:
    # - H:/bla/bla - будет создана база H: где? Да прямо в корне диска H:. Вывод 1С win-xp:
    #   `Создание информационной базы ("File=H:;Locale = "ru_RU";") успешно завершено`
    # - H:/путь/котрого/нет/имябазы - будет оздана база в каталоге по умолчанию
    #   с именем InfoBase[N]. Вывод 1С win-xp:
    #   `Создание информационной базы ("File = "C:\Documents and Settings\vlv\Мои документы\InfoBase41";Locale = "ru_RU";") успешно завершено`
    #   в linux отработает корректно и попытается содать каталоги или вылитит с
    #   ошибкой ?$>0
    # - ../empty.ib - использование относительного пути в win создает базу по
    #   умолчанию как в предидущем пункте в linux создаст базу empty.ib в текущем
    #   каталоге при этом вывод 1C в linux:
    #   `Создание информационной базы ("File=../empty.ib;Locale = "en_US";") успешно завершено`
    # - H:\путь\содержит-тире - в win создаст базу H:\путь\содержит вывод 1С:
    #   `Создание информационной базы ("File=H:\genm\содержит;Locale = "ru_RU";") успешно завершено`
    #   в linux отработет корректно

    require 'ass_launcher/enterprise/cli'

    # Class for wrapping 1C platform binary executables suach as 1cv8.exe and
    # 1cv8c.exe. Class makes it easy to juggle the different versions of 1C
    #
    # @abstract
    # @api private
    # @note (see #version)
    # @note (see #arch)
    class BinaryWrapper
      include AssLauncher::Support::Platforms
      attr_reader :path

      def initialize(binpath)
        @path  = platform.path(binpath).realpath
        fail ArgumentError, "Is not a file `#{binpath}'" unless @path.file?
        fail ArgumentError, "Invalid binary #{@path.basename} for #{self.class}"\
          unless @path.basename.to_s.upcase ==  expects_basename.upcase
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
        @version ||= extract_version(@path.to_s)
      end

      # Define arch on 1C platform.
      # @note Arch of platform  actual for Linux. In windows return i386
      # @api public
      # @return [String]
      def arch
        @arch ||= extract_arch(@path.to_s)
      end

      # Extract version from path
      def extract_version(realpath)
        if platform.linux?
          extracted = realpath.to_s.split('/')[-3]
        else
          extracted = realpath.to_s.split('/')[-3]
        end
        extracted =~ /(\d+\.\d+\.?\d*\.?\d*)/i
        extracted = ($1.to_s.split('.') + [0,0,0,0])[0,4].join('.')
        Gem::Version.new(extracted)
      end
      private :extract_version

      def extract_arch(realpath)
        if platform.linux?
          extracted = realpath.to_s.split('/')[-1]
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
        self.version <=> other.version
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
        version.to_s.split('.')[0,2].join('.')
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
      # @param [String] args string arguments for run 1C binary wrapped in
      #  +cmd.exe+ or +sh+ script like as: +'/Arg1 "Value" /Arg2 "value"'+
      # @option options (see AssLauncher::Support::Shell::Script#initialize}
      # @return [AssLauncher::Support::Shell::Script]
      def to_script(args = '', options = {})
        AssLauncher::Support::Shell::Script.\
          new("#{path.win_string.to_cmd} #{args}", options)
      end
      private :to_script

      # @param run_mode [Symbol]
      #  Valid values define in the {#run_modes}
      # @raise [ArgumentError]
      # @return [String] run mode for run 1C binary
      def mode(run_mode)
        fail ArgumentError, "Invalid run_mode `#{run_mode}' for #{self.class}"\
          unless run_modes.include? run_mode
            run_mode.to_s.upcase
      end
      private :mode

      def build_args(run_mode, &block)
        arguments_builder = Cli::ArgumentsBuilder.new(self, run_mode)
        arguments_builder.instance_eval &block
        arguments_builder.builded_args.to_array
      end
      private :build_args

      # @example
      #  cl = AssLauncher::Enterprise.thick_clients('~> 8.3.6').last
      #  raise 'Can't find 1C binary' if cl.nil?
      #
      #  # Dump infobase
      #
      #  conn_str = AssLauncher::Support::ConnectionString.\
      #    new('File="//host/infobase"')
      #
      #  command = cl.build_command(:designer, conn_str.to_args) do
      #    connection_string conn_str
      #    DumpIB './infobase.dt'
      #  end
      #  ph = command.run.wait
      #
      #  ph.result.verify!
      #
      #  # Crete info base
      #
      #  ph = cl.build_command(:createinfobase) do
      #    connection_string "File='//host/new.ib';"
      #    _UseTemplate './application.cf'
      #    _AddInList
      #  end.run.wait
      #
      #  ph.result.verify!
      #
      #  # Check configuration
      #
      #  ph = cl.build_command(:designer) do
      #    CheckConfig do
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
      #  #   message("Ass listen:  "+LaunchParameter)
      #  #   exit()
      #  # endprocedure
      #
      #  ph = cl.build_command(:enterprise) do
      #    connection_string 'File="./infobase"'
      #    _Execute './processor.epf'
      #    _C 'Hello World'
      #  end.run.wait
      #
      #  ph.result.verify!
      #
      #  puts ph.result.assout #=> 'Ass listen: Hello World'
      #
      def command(run_mode, args = [], options = {}, &block)
        _args = args.dup
        _args.unshift mode(run_mode)
        _args += build_args &block if block_given?
        to_command(_args, options)
      end

      # Ruan as script. It waiting for script executed.
      # Not use arguments_builder and not given block
      # Argumets string make as you want
      #
      # @example
      #
      # script = cl.build_script(:makeinfobase, 'File="new.ib"')
      # ph = script.run # this waiting until process executing
      # ph.result.expected_assout = /\("File=new.ib;.*"\) успешно завершено/
      # ph.result.verify!
      #
      def script(run_mode, args = '', options = {})
        _args = "#{mode(run_mode)} #{args}"
        to_script(args, options)
      end

      # Wrapper for 1C thin client binary
      class ThinClient < BinaryWrapper
        # Define run modes of thin client
        def run_modes
          { :enterprise => ''}
        end

        def accepted_connstr
          [:file, :server, :http]
        end

#        # Return suitable instanse for run client in enterprise mode with validate
#        # cmd arguments
#        # @return [CliBuilder::Launcher]
#        def enterprise(connectstr)
#          mode(:enterprise).new self, connectstr
#        end
      end

      class ThickClient < ThinClient
        # (see ThinClient)
        def run_modes
          super.merge(
            { :designer => '',
              :createinfobase => ''
          })
        end

        def accepted_connstr
          [:file, :server]
        end
      end
    end
  end
end
