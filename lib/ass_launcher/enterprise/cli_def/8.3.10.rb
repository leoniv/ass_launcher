module AssLauncher::Enterprise::CliDef
  group :other do
    mode :enterprise do
      flag '/EnableCheckScriptCircularRefs',
        'включает поиск циклических ссылок'
    end
  end

  group :packge_mode do
    mode :designer do
      change '/DumpConfigToFiles' do
        flag '-update', 'будут выгружены файлы версии которых отличаются'\
          ' от ранее выгруженных. Версии файлов хранятся в файле'\
          ' ConfigDumpInfo.xml. Если текущая версия формата выгрузки не'\
          ' совпадает с версией формата в файле версий или если файл версий'\
          ' не найден, выполнение завершится с ошибкой'
        flag '-force', 'используется вместе с -update. Если -update не может'\
          ' быть выполнен, вместо завершения с ошибкой, будет произведена'\
          ' полная выгрузка.'
        path '-getChanges', 'в указанный файл будут выведены изменения текущей'\
          ' конфигурации относительно существующей выгрузки или относительно'\
          ' информации хранящейся в фале ConfigDumpInfo.xml куазанном в опции'\
          ' -configDumpInfoForChanges'
        path '-configDumpInfoForChanges', 'указывает файл версий, который будет'\
          ' использован для сравнения изменений. Только совместно с опциями'\
          ' -update и -getChanges'
        path '-listfile', 'файл со списком обектов которые требуется выгрузить'
      end

      change '/LoadConfigFromFiles' do
        flag '-updateConfigDumpInfo', 'указывает, что в конце загрузки в'\
          ' каталоге xml дампа будет создан файл версий ConfigDumpInfo.xml.'\
          ' при частичной загрузке, опции -files и -listfile, ConfigDumpInfo.xml'\
          ' будет обновлен'
      end
    end
  end

  group :agent_mode do
    mode :designer do

      flag '/AgentMode', 'запуск конфигуратора в режиме агента'

      string '/AgentListenAddress', 'IP-адрес конфигуратора в режиме агента.'\
        ' По умолчанию 127.0.0.1'

      string '/AgentPort', 'номер порта ssh-сервера конфигуратора в'\
        ' режиме агента. По умолчанию 1543'

      path_exist '/AgentBaseDir', 'базовый каталог sftp-сервера конфигуратора'\
        ' в режиме агента по умолчанию использует рабочий каталог инфобазы'

      path_exist '/AgentSSHHostKey', 'путь к файлу закрытого ключа.'\
        'Если не указан используйте флаг /AgentSSHHostKeyAuto'

      flag '/AgentSSHHostKeyAuto', 'поиск файла закрытого ключа будет'\
        ' выполняться в рабочем каталоге инфобазы. Если не найден будет'\
        ' сгенерирован новый ключ RSA/2048'
    end
  end
end
