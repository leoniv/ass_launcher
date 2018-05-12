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
      string '/ReduceEventLogSize',
        'сокращение журнала регистрации, дата в формате ГГГГ-ММ-ДД',
        value_validator: (Proc.new do |value|
            fail ArgumentError,
              "Use format YYYY-MM-DD for /ReduceEventLogSize parameter. Given"\
              " `#{value}'" if /\A\d{4}-\d{2}-\d{2}\z/ =~ value
          end) do
        path '-saveAs', 'файл для сохранения копии удаляемых записей'
        flag '-KeepSplitting',
          'требуется сохранить разделение на файлы по периодам'
      end
      path '/CreateTemplateListFile',
        'создание файла шаблонов конфигураций в указанном файле' do
        flag '-TemplatesSourcePath',
          'путь для поиска файлов шаблонов конфигураций'
      end
      flag '/Visible',
        'делает исполнение пакетной команды видимым пользователю'
    end
  end

  group :repository do
    mode :designer do
      path_exist '/ConfigurationRepositoryF', 'каталог хранилища'
      string '/ConfigurationRepositoryN', 'имя пользователя хранилища'
      string '/ConfigurationRepositoryP', 'пароль пользователя хранилища'
      path '/ConfigurationRepositoryDumpCfg',
        'сохранить конфигурацию из хранилища в файл' do
        string '-v', 'номер версии хранилища'
      end
      path_exist '/ConfigurationRepositoryUpdateCfg',
        'обновить конфигурацию хранилища из хранилища' do
        string '-v', 'номер версии хранилища'
        flag '-revised', 'получать захваченные объекты, если потребуется'
        flag '-force',
          'подтверждение получения новых или удаления существующих'\
          ' объектов конфигурации'
      end
      flag '/ConfigurationRepositoryUnbindCfg',
        'отключение конфигурации от хранилища' do
        flag '-force', 'принудительное отключение от хранилища'
      end
      path_exist '/ConfigurationRepositoryReport',
        'построение отчета по истории хранилища' do
        string '-NBegin', 'номер версии начала отчета'
        string '-NEnd', 'номер версии окончания отчета'
        flag '-GroupByObject', 'с группировкой по объектам'
        flag '-GroupByComment', 'с группировкой по комментарию'
      end
    end
  end

  group :distribution do
    mode :designer do
      flag '/CreateDistributionFiles', 'создание файлов поставки и обновления' do
        path '-cffile', 'создать дистрибутив (.cf файл)'
        path '-cfufile', 'создать обновление дистрибутива (.cfu файл)'
        path '-f', 'дистрибутив включаемый в обновление (.cf файл)'
        string '-v', 'версия дистрибутива включаемого в обновление'
        path_exist '-digisign', 'файл с параметрами лицензирования'
      end
    end
  end

  skip '/AppAutoCheckVersion'
  skip '/AppAutoCheckMode'
  skip '/IBName'
  skip '/TComp'
  skip '/DisplayAllFunctions'
  skip '/SimulateServerCallDelay'
  skip '/DumpConfigFiles'
  skip '/LoadConfigFiles'
  skip '/ConvertFiles'
  skip '/RunEnterprise'
  skip '/DumpResult'
  skip '/RegServer '
  skip '/UnregServer'
  skip 'WebclientMode'
end
