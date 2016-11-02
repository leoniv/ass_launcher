module AssLauncher::Enterprise::CliDef
  group :other do
    mode :enterprise do
      flag '/HttpsForceTLS1_0',
        'использование протокола TLS версии 1.0. Одновременное'\
        ' использование с параметром /HTTSForceSSLv3 не допускается',
        thin
      restrict '/HttpsForceSSLv3'
      flag '/HttpsForceSSLv3',
        'использование протокола SSL версии 3.0. Одновременное'\
        ' использование с параметром /HttpsForceTLS1_0 не допускается',
        thin
      flag '/EnableCheckServerCalls',
        'включает режим проверки контекстных серверных вызовов в обработчиках'\
        ' формы, в которых вызовы сервера запрещены'
    end

    mode :enterprise, :webclient do
      restrict '/EnableCheckExtensionsAndAddInsSyncCalls'
      flag '/EnableCheckExtensionsAndAddInsSyncCalls',
        'включает режим строгой проверки использования синхронных вызовов',
        thin, web
    end
  end

  group :packge_mode do
    mode :designer do
      flag '/IBRestoreIntegrity',
        'восстановление структуры информационной базы. Данный параметр'\
        ' рекомендуется использовать в случае, если предыдущее обновление'\
        ' конфигурации базы данных не было завершено. При использовании'\
        ' данного параметра, остальные параметры запуска будут проигнорированы'
      flag '/CheckCanApplyConfigurationExtensions',
        'проверка применимости расширений' do
        string '-Extension', 'имя расширения'
        flag '-AllZones',
          'проверка выполняется для расширений во всех областях информационной'\
          ' базы. Не допускается использование совместно с -Extension или -Z'
        string '-Z', 'установка разделителей'
      end

      flag '/CompareCfg', 'построение отчета о сравнении конфигурации' do
        chose '-FirstConfigurationType',
          'тип первой конфигурации',
          chose_list:\
          chose_list(
            :MainConfiguration => 'основная конфигурация'\
            ' -FirstConfigurationKey не используется',
            :DBConfiguration => 'конфигурация базы данных'\
            ' -FirstConfigurationKey не используется',
            :VendorConfiguration => 'конфигурация поставщика'\
            ' -FirstConfigurationKey ожидает имя конфигурации',
            :ExtensionConfiguration => 'расширение конфигурации'\
            ' -FirstConfigurationKey ожидает имя расширения',
            :ExtensionDBConfiguration => 'расширение конфигурации (база данных)'\
            ' -FirstConfigurationKey ожидает имя расширения',
            :ConfigurationRepository => 'конфигурация из хранилища'\
            ' -FirstConfigurationKey ожидает версию',
            :File => 'файл конфигурации(расширения)'\
            ' -FirstConfigurationKey ожидает путь к .cf(.cfe) файлу',
          )
        string '-FirstConfigurationKey',
          'идентификатор первой конфигурации. Использование'\
          ' см. -FirstConfigurationType',
          value_validator: (proc do |value|
            if value =~ /\.(cf|cfe)\z/i
              AssLauncher::Support::Platforms.path(value).realdirpath.to_s
            else
              value
            end
          end)
        chose '-SecondConfigurationType',
          'тип второй конфигурации',
          chose_list:\
          chose_list(
            :MainConfiguration => 'основная конфигурация'\
            ' -SecondConfigurationKey не используется',
            :DBConfiguration => 'конфигурация базы данных'\
            ' -SecondConfigurationKey не используется',
            :VendorConfiguration => 'конфигурация поставщика'\
            ' -SecondConfigurationKey ожидает имя конфигурации',
            :ExtensionConfiguration => 'расширение конфигурации'\
            ' -SecondConfigurationKey ожидает имя расширения',
            :ExtensionDBConfiguration => 'расширение конфигурации (база данных)'\
            ' -SecondConfigurationKey ожидает имя расширения',
            :ConfigurationRepository => 'конфигурация из хранилища'\
            ' -SecondConfigurationKey ожидает версию',
            :File => 'файл конфигурации(расширения)'\
            ' -SecondConfigurationKey ожидает путь к .cf(.cfe) файлу',
          )
        string '-SecondConfigurationKey',
          'идентификатор второй конфигурации. Использование'\
          ' см. -SecondConfigurationType',
          value_validator: (proc do |value|
            if value =~ /\.(cf|cfe)\z/i
              AssLauncher::Support::Platforms.path(value).realdirpath.to_s
            else
              value
            end
          end)
        chose '-MappingRule',
          'правило установки соответствий объектов для неродственных конфигураций',
          chose_list:\
          chose_list(
            :ByObjectNames => 'по именам (по умолчанию)',
            :ByObjectIDs => 'по идентификаторам')
        path_exist '-Objects','путь к файлу содержащему список объектов.'\
          ' Если не указан, отчет строится по всей конфигурации'
        chose '-ReportType', 'тип отчета',
          required: true,
          chose_list:\
          chose_list(
            :Brief => 'краткий',
            :Full => 'полный')
        flag '-IncludeChangedObjects',
          'включать в отчет измененные подчиненные объекты'
        flag '-IncludeDeletedObjects',
          'включать в отчет удаленные подчиненные объекты'
        flag '-IncludeAddedObjects',
          'включать в отчет добавленные подчиненные объекты'

        chose '-ReportFormat', 'формат файла отчета',
          chose_list:\
          chose_list(
            :txt => 'текстовый',
            :mxl => 'табличный документ')
        path '-ReportFile', 'путь к результирующему файлу отчета'
      end
    end
  end
end
