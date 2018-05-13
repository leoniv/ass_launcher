module AssLauncher::Enterprise::CliDef
  restrict '/MAUpdatePublication'
  restrict '/MAWriteFile'

  group :packge_mode do
    mode :designer do
      change '/CheckConfig' do
        flag '-MobileClient', 'синт. контроль модулей в режиме'\
          ' мобильного клиента'
        flag '-MobileClientDigiSign', 'проверка подписи мобильного клиента'
      end

      change '/CheckModules' do
        flag '-MobileClient', 'в контексте мобильного клиента'
      end

      change '/CompareCfg' do
        restrict '-FirstConfigurationType'
        restrict '-FirstConfigurationKey'
        restrict '-SecondConfigurationType'
        restrict '-SecondConfigurationKey'
        chose '-FirstConfigurationType',
          'тип первой конфигурации',
          chose_list:\
          chose_list(
            :MainConfiguration => 'основная конфигурация',
            :DBConfiguration => 'конфигурация базы данных',
            :VendorConfiguration => 'конфигурация поставщика',
            :ExtensionConfiguration => 'расширение конфигурации',
            :ExtensionDBConfiguration => 'расширение конфигурации'\
              ' (база данных)',
            :ConfigurationRepository => 'конфигурация из хранилища',
            :ExtensionConfigurationRepository => 'расширение'\
            ' конфигурации из хранилища',
            :File => 'файл конфигурации(расширения)'
          )
        chose '-SecondConfigurationType',
          'тип второй конфигурации',
          chose_list:\
          chose_list(
            :MainConfiguration => 'основная конфигурация',
            :DBConfiguration => 'конфигурация базы данных',
            :VendorConfiguration => 'конфигурация поставщика',
            :ExtensionConfiguration => 'расширение конфигурации',
            :ExtensionDBConfiguration => 'расширение конфигурации'\
              ' (база данных)',
            :ConfigurationRepository => 'конфигурация из хранилища',
            :ExtensionConfigurationRepository => 'расширение'\
            ' конфигурации из хранилища',
            :File => 'файл конфигурации(расширения)'
          )
        string '-FirstName', 'имя конфигурации для типов'\
          ' *Configuration'
        path '-FirstFile', 'путь к файлу для типа :File'
        string '-FirstVersion', 'версия в хранилище, для типов'\
          ' *Repository'
        string '-SecondName', 'имя конфигурации для типов'\
          ' *Configuration'
        path '-SecondFile', 'путь к файлу для типа :File'
        string '-SecondVersion', 'версия в хранилище, для типов'\
          ' *Repository'
      end

      flag '/MobileAppUpdatePublication', 'обновление публикации'\
        ' мобильного приложения'
      path '/MobileAppWriteFile', 'записывает xml файл мобильного'\
        ' приложения'


      change '/UpdateDBCfg' do
        restrict '-Server'
        chose '-Server', 'обновление будет выполняться на сервере',
          chose_list: chose_list(
            :'-v1' => '1-я версия механизма',
            :'-v2' => '2-я версия механизма')
      end
    end
  end

  group :distribution do
    mode :designer do
      change '/CreateDistributionFiles' do
        flag '-WarningsAsErrors', 'все предупредительные сообщения'\
          ' трактуются как ошибки'
      end

      change '/CreateDistributive' do
        flag '-WarningsAsErrors', 'все предупредительные сообщения'\
          ' трактуются как ошибки'
      end
    end
  end

  group :repository do
    mode :designer do
      change '/ConfigurationRepositoryAddUser' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryBindCfg' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryClearCache' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryClearGlobalCache' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryClearLocalCache' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryCommit' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryCreate' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryDumpCfg' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryLock' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryOptimizeData' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryReport' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositorySetLabel' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryUnbindCfg' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryUnlock' do
        string '-Extension', 'имя расширения'
      end

      change '/ConfigurationRepositoryUpdateCfg' do
        string '-Extension', 'имя расширения'
      end
    end
  end
end
