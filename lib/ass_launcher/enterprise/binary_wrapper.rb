# encoding: utf-8

module AssLauncher
  module Enterprise
    # TODO memo fucking 1C: команда `CEATEINFOBASE` принимает фаловую строку
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
    # @abstract
    class BinaryWrapper
      include AssLauncher::Support::Platforms
      attr_reader :path

      def initialize(binpath)
        @path  = platform.path(binpath).realpath
        fail ArgumentError, "Is not a file `#{binpath}'" unless @path.file?
        fail ArgumentError, "Invalid binary #{@path.basename} for #{self.class}"\
          unless @path.basename.to_s ===  /#{expects_basename}/i
      end

      def version
        @version |= exract_version(@path.to_s)
      end

      def arch
        @arch |= extract_arch(@path.to_s)
      end

      def exract_version(realpath)
        if platform.linux?
          extracted = realpath.to_s.split('/')[-3]
        else
          extracted = realpath.to_s.split('/')[-3]
        end
        extracted =~ /(\d+\.\d+\.?\d*\.?\d*)/i
        extracted = ($1.to_s.split('.') + [0,0,0,0])[0,4].join('.')
        Gem::Version.new(extracted)
      end
      private :exract_version

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
      def <=>(other)
        self.version <=> other.version
      end

      def expects_basename
        Enterprise.binaries(self.class)
      end
      private :expects_basename

      # True if file exsists
      def exists?
        path.file?
      end

      def major_v
        version.to_s.split('.')[0,2].join('.')
      end

      def to_s
        path.to_s
      end

      def to_cmd(command, connection_string)
        cmd = "#{to_s.escape} #{command}"
        if connection_string
          cmd = "#{cmd} #{connection_string.to_cmd(self)}"
        end
        cmd
      end
    end

    class ThinClient < BinaryWrapper
      def enterprise(connectstr = nil)
        Support::Shell::Command.new(to_cmd('ENTERPRISE', connectstr))
      end
    end

    class ThickClient < ThinClient
      def designer(connectstr = nil)
        Support::Shell::Command.new(to_cmd('DESIGNER', connectstr))
      end

      def createinfobase(connectstr = nil)
        Support::Shell::Command.new(to_cmd('CREATEINFOBASE', connectstr))
      end
    end

    class WebClient < BinaryWrapper
      def initialize(binpath)
        super
        @version = Gem::Version.new('')
        @arch    = FFI::Platform::ARCH
      end

      def expects_basename
        '(firefox|iexplore|chrome|safary)'
      end

      # Return forked shell command
      def enterprise(connectstr = nil)
        Support::Shell::Fork.new(to_cmd('', connectstr))
      end
    end
  end
end
