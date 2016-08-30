# encoding: utf-8
module AssLauncher
  #
  module Enterprise
    # 1C:Enterprise CLI definition
    module CliDef
      DEFS_PATH = File.expand_path('../cli_def', __FILE__)
      extend Cli::SpecDsl
      def self.version_from_file_name(file)
        enterprise_version File.basename(file, '.rb')
      end
      private

      describe_mode :enterprise, 'Запуск в режиме предприятия',
                    'ENTERPRISE [parameters]'

      describe_mode :designer, 'Запуск в режиме конфигуратора',
                    'DESIGNER [parameters]'

      describe_mode :createinfobase, 'Создание информационной базы',
                    'CREATEINFOBASE <connection_string> [parameters]'

      describe_mode :webclient, 'Запуск в режиме web клиента',
                    'WEB [parameters] URL'

      define_group :connection,
                   'Соединение с информационной базой', 0

      define_group :authentication,
                   'Авторизация пользователя информационной базы', 10

      define_group :debug,
                   'Отладка и тестирование', 30

      define_group :packge_mode,
                   'Пакетный режим конфигуратора', 40

      define_group :repository,
                   'Работа с хранилищем конфигурации', 50

      define_group :distribution,
                   'Cоздание файлов поставки и обновления', 60

      define_group :other, 'Прочие', 100

      Dir.glob(File.join(DEFS_PATH, '*.rb')).each do |l|
        version_from_file_name l
        require l
      end
    end
  end
end
