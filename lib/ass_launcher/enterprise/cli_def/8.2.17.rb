# encoding: utf-8
module AssLauncher::Enterprise::CliDef
  group :connection do
    mode :enterprise do
      url '/WS', 'url соединения c базой опубликованной через web сервер', thin
      flag '/NoProxy', 'запретить использование прокси', thin
      flag '/Proxy', 'использовать указанные настройки прокси', thin do
        url '-PSrv', 'адрес прокси', required: true
        num '-PPort', 'порт прокси', required: true
        string '-PUser', 'имя пользователя прокси'
        string '-PPwd', 'имя пользователя прокси'
      end
    end
  end

  group :authentication do
    mode :enterprise do
      switch '/WSA',
        'применение аутентификации пользователя на веб-сервере. Используется'\
        ' аутентификация средствами операционной системы',
        switch_list: switch_list(
          :+ => 'применение аутентификации (значение по умолчанию)',
          :- => 'запрет применения'
        )
      string '/WSN',
        'имя пользователя для аутентификации на веб-сервере', thin
      string '/WSP',
        'пароль пользователя для аутентификации на веб-сервере', thin
    end
  end

  group :debug do
    mode :enterprise, :webclient do
      flag '/DisplayPerformance',
        'показывать количество вызовов сервера и объем данных'
    end
  end

  group :other do
    mode :enterprise, :designer, :webclient do
      string '/Z', 'установка разделителей'
    end

    mode :enterprise, :webclient do
      string '/VL', 'код локализации сеанса'
      flag '/UsePrivilegedMode', 'запуск в режиме привилегированного сеанса'
      chose  '/O', 'определяет скорость соединения',
        thin, web,
        chose_list: chose_list(Normal: 'обычная', Low: 'низкая')
    end

    mode :enterprise, :designer do
      switch '/UseHwLicenses',
        'определяет режим поиска локального ключа защиты',
        switch_list: switch_list(:+ => 'поиск выполняется',
                                 :- => 'поиск не выполняется')
    end

    mode :enterprise do
      flag '/RunModeOrdinaryApplication',
        'запуск толстого клиента в режиме обычного приложения', thick
      flag '/RunModeManagedApplication',
        'запуск толстого клиента в режиме управляемого приложения', thick
      flag '/ClearCache', 'очистка кэша клиент-серверных вызовов'
      flag '/itdi', 'режим интерфейса с использованием закладок'
    end
  end

  group :packge_mode do
    mode :designer do
      change '/CheckModules' do
        restrict '-ClientServer'
        restrict '-ExternalConnectionServer'
        flag '-ThinClient', 'в контексте тонкого клиента'
        flag '-WebClient', 'в контексте веб-клиента'
        flag '-ExternalConnection', 'в контексте внешнего соединения'
        flag '-ThickClientOrdinaryApplication', 'в контексте толстого клиента'
      end
      change '/CheckConfig' do
        restrict '-ClientServer'
        restrict '-Client'
        restrict '-ConfigLogicalIntegrity'
        flag '-ConfigLogIntegrity',
          'проверка логической целостности конфигурации'
        flag '-ThinClient',
          'синт. контроль модулей для режима управляемого приложения'\
          ' (тонкий клиент), выполняемого в файловом режиме'
        flag '-WebClient', 'синт. контроль модулей в режиме веб-клиента'
        flag '-ThickClientManagedApplication',
          'синт. контроль модулей в режиме управляемого приложения'\
          ' (толстый клиент), выполняемого в файловом режиме'
        flag '-ThickClientServerManagedApplication',
          ' синт. контроль модулей в режиме управляемого приложения'\
          ' (толстый клиент), выполняемого в клиент-серверном режиме'
        flag '-ThickClientOrdinaryApplication',
          'синт. контроль модулей в режиме обычного приложения'\
          ' (толстый клиент), выполняемого в файловом режиме'
        flag '-ThickClientServerOrdinaryApplication',
          'синт. контроль модулей в режиме обычного приложения'\
          ' (толстый клиент), выполняемого в клиент-серверном режиме'
        flag '-ExtendedModulesCheck',
          'проверка обращений к методам и свойствам объектов "через точку"'\
          ' (для ограниченного набора типов)'
      end
    end
  end

  skip '/AppAutoCheckVersion'
  skip '/AppAutoCheckMode'
  skip '/IBName'
  skip '/TComp'
  skip '/DisplayAllFunctions'
  skip '/SimulateServerCallDelay'
  skip 'WebclientMode'
end
