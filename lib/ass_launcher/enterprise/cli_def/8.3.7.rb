module AssLauncher::Enterprise::CliDef
  group :packge_mode do
    mode :designer do
      change '/LoadConfigFromFiles' do
        string '-Files',
          'список файлов которые требуется загрузить.'\
          ' Список разделяется запятыми. Не используется'\
          ' если указан ключ -listfile'
        path '-ListFile',
          'файл со списком файлов которые требуется загрузить.'\
          ' Не используется если указан ключ -Files'
        chose '-Format',
          'формат загрузки файлов при частичной загрузке',
              chose_list:\
              chose_list(:Hierarchical => 'иерархический формат. По умолчанию',
                         :Plain => 'линейный формат')
      end
      change '/DumpConfigToFiles' do
        chose '-Format',
          'формат загрузки файлов при частичной загрузке',
              chose_list:\
              chose_list(:Hierarchical => 'иерархический формат. По умолчанию',
                         :Plain => 'линейный формат')
      end
      flag '/ManageCfgSupport',
        'управление настройками поддержки конфигурации' do
        flag '-DisableSupport',
          'снять конфигурацию с поддержки'
        flag '-Force',
          'снять с поддержки даже если в конфигурации не разрешены изменения'
      end
    end
  end
end
