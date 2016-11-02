module AssLauncher::Enterprise::CliDef
  group :other do
    mode :enterprise do
      flag '/EnableCheckModal',
        'запуск в режиме "строгой" проверки использования модальных методов'
      url '/URL',
        'переход по ссылке в формате e1c://'
      flag '/HttpsForceSSLv3',
        'использование протокола SSL версии 3.0', thin
    end
  end

  group :repository do
    mode :designer do
      flag '/ConfigurationRepositoryClearGlobalCache',
        'очистка глобального кэша версий конфигурации в хранилище'
      flag '/ConfigurationRepositoryClearLocalCache',
        'очистка локального кэша версий конфигурации'
    end
  end
end
