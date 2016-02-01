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
    class BinaryWrapper

      #'FIXME' Надо делать отдельный враппер для тонкого и толстого клиента

      attr_reader :version, :path, :arch

      def initialize(binpath)
        raise 'FIXME'
        @path  = platform.path(binpath)
        @version = exract_version(@path.realpath.to_s)
        @arch    = extract_arch(@path.realpath.to_s)
        @thin    = CLIENTS[:thin]
        @thick   = CLIENTS[:thick]
      end

      def exract_version(realpath)
        if linux?
          extracted = realpath.split('/')[-2]
        else
          extracted = realpath.split('/')[-2]
        end
        extracted =~ /(?<version>\d\.\d\.?\d?\.?\d?)/i
        extracted = (extracted.split('.') + [0,0,0,0])[0,4].join('.')
        begin
          v = Support.ass_version(version)
        rescue Exseptin => e
          v = Support.ass_version
        end
      end
      private :exract_version

      # Compare wrappers on version
      # @param other [BinaryWrapper]
      # @return [Bollean]
      def <=>(other)
        self.version <=> other.version
      end

      # Return path to thin client file
      #@return [AssLauncher::Support::Platforms::Path]
      def thin_client_path
        @bindir.join(CLIENTS[:thin])
      end

      # True if thin clent file exsists
      def thin_exists?
        thin_client.file?
      end

      def thick_client_path
        @bindir.join(CLIENTS[:thick])
      end

      def thick_exists?
        File.file? thick_client
      end

      def major_v
        version.redaction
      end
    end
  end
end
