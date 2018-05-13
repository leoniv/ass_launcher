module AssLauncher::Enterprise::CliDef
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
    end
  end
end
