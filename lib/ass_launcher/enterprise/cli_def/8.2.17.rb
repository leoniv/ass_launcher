# encoding: utf-8
module AssLauncher::Enterprise::CliDef
  group :connection do
    mode :enterprise, :designer do
      path_exist '/F', 'путь к файловой информационной базе'
      string '/S', 'адрес серверной информационной базы. Вид "host:port/ibname"'
    end

    mode :enterprise do
      url '/WS', 'url соединения c базой опубликованной через web сервер', thin
      flag '/SAOnRestart', 'запрос пароля при перезапуске системы'
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
    mode :enterprise, :designer, :webclient do
      string '/N', 'имя пользователя информационной базы'
      string '/P', 'пароль пользователя информационной базы'
    end

    mode :enterprise, :webclient do
      switch '/WA',
        'аутентификация средствами операционной системы. Если не указано'\
        ' используется /WA+', thin, web,
        switch_list: switch_list(
          :+ => 'обязательное применение',
          :- => 'запрет применения'
        )
    end

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
      url '/DebuggerURL', 'url отладчика'
      flag '/DisplayPerformance',
        'показывать количество вызовов сервера и объем данных'
    end

    mode :enterprise do
      url '/Debug', 'запуск 1С:Предприятия в отладочном режиме'
    end
  end

  group :other do
    mode :createinfobase do
      path_exist '/UseTemplate', 'создание информационной базы на основе'\
        ' дампа (.dt файл) или конфигурации (.cf файл)'
      string '/AddInList', 'имя под которым надо добавить базу в'\
        ' пользовательский файл .v8i'
    end

    mode :enterprise, :designer, :createinfobase do
      path_exist('/Out', 'файл используемый 1С вместо stdout и stderr.'\
                 ' Выводятся служебные сообщения и сообщения метода Сообщить()')
      flag('/DisableStartupDialogs', 'подавляет gui диалоги')
      flag('/DisableStartupMessages', 'подавляет gui сообщения')
    end

    mode :enterprise, :designer, :webclient do
      string '/L', 'указывается код языка интерфейса платформы:'\
        ' ru - Русский, en - Английский и т.д. Список см. в документации 1С'
      string '/Z', 'установка разделителей'
    end

    mode :enterprise, :webclient do
      string '/C', 'передача строкового значения в экземпляр 1С приложения.'\
        ' Значение доступно в глобальной переменной `ПараметрЗапуска`.'\
        ' Использовать в строке двойные кавычки запрещено работает криво.',
        value_validator: (Proc.new do |value|
          fail ArgumentError,
            'In /C parameter char `\"` forbidden for use' if /"/ =~ value
        end)
      string '/VL', 'код локализации сеанса'
      flag '/UsePrivilegedMode', 'запуск в режиме привилегированного сеанса'
      chose  '/O', 'определяет скорость соединения',
        thin, web,
        chose_list: chose_list(Normal: 'обычная', Low: 'низкая')
      switch '/SLev', 'определяет уровень защищенности соединения с сервером',
        thin, web,
        switch_list: switch_list(:'0' => '',
                                 :'1' => '',
                                 :'2' => ''
                                )
    end

    mode :enterprise, :designer do
      switch '/UseHwLicenses',
        'определяет режим поиска локального ключа защиты',
        switch_list: switch_list(:+ => 'поиск выполняется',
                                 :- => 'поиск не выполняется')
      path_exist '/RunShortcut',
        'позволяет запустить систему со списком баз из указанного файла v8i'
    end

    mode :enterprise do
      flag '/LogUI', 'логирование действий пользователя'
      flag '/RunModeOrdinaryApplication',
        'запуск толстого клиента в режиме обычного приложения', thick
      flag '/RunModeManagedApplication',
        'запуск толстого клиента в режиме управляемого приложения', thick
      string '/UC', 'код для установки соединения с заблокированной базой'
      path_exist '/Execute', 'запуска внешней обработки в режиме 1С:Предприятие непосредственно после старта системы'
      flag '/ClearCache', 'очистка кэша клиент-серверных вызовов'
      flag '/itdi', 'режим интерфейса с использованием закладок'
    end
  end

  group :packge_mode do
    mode :designer do
      path '/DumpIB', 'выгрузка дампа информационной базы'
      path_exist '/RestoreIB', 'загрузка информационной базы из дампа'
      path '/DumpCfg', 'сохранение конфигурации в файл'
      path_exist '/LoadCfg', 'загрузка конфигурации из файла'
      flag '/UpdateDBCfg', 'обновление конфигурации базы данных' do
        flag '-WarningsAsErrors',
          'все предупредительные сообщения трактуются как ошибки'
        flag '-Server', 'обновление будет выполняться на сервере'
      end
      path_exist '/UpdateCfg',
        'обновление конфигурации находящейся на поддержке из .cf или .cfu файла'
      path '/DumpDBCfg', 'сохранение конфигурации базы данных в файл'
      flag '/RollbackCfg', 'возврат к конфигурации базы данных'
      flag '/CheckModules', 'синт. контроль' do
        flag '-ThinClient', 'в контексте тонкого клиента'
        flag '-WebClient', 'в контексте веб-клиента'
        flag '-Server', 'в контексте сервера'
        flag '-ExternalConnection', 'в контексте внешнего соединения'
        flag '-ThickClientOrdinaryApplication', 'в контексте толстого клиента'
      end

      flag '/IBCheckAndRepair',
        'выполнить тестирование и исправление информационной базы' do
        flag '-ReIndex', 'реиндексация таблиц'
        flag '-LogIntegrity', 'проверка логической целостности'
        flag '-LogAndRefsIntegrity',
          'проверка логической и ссылочной целостности'
        flag '-RecalcTotals', 'пересчет итогов'
        flag '-IBCompression', 'сжатие таблиц'
        flag '-Rebuild', 'реструктуризация таблиц информационной базы'
        flag '-TestOnly', 'только тестирование'
        switch '-BadRef', 'действия для битых ссылок',
          switch_list: switch_list(
          Create: 'создавать объекты для битых ссылок',
          Clear: 'очищать объекты от битых ссылок',
          None: 'не изменять'
          )
        switch '-BadData', 'при частичной потере объектов',
          switch_list: switch_list(
          Create: 'создавать объекты',
          Delete: 'удалять объекты'
          )
        flag '-UseStartPoint',
          'использовать сохраненную точку возврата для продолжения тестирования'\
          ' с места, на котором оно было прервано'
        switch '-TimeLimit', 'ограничение максимального времени сеанса'\
          ' тестирования. Строка формата hhh:mm',
          value_validator: (Proc.new do |value|
          fail ArgumentError,
            "Use format hhh:mm for -TimeLimit parameter. Given: `#{value}'" if\
            /\A\d{1,3}:\d{2}\z/ =~ value
          end),
          switch_value: (Proc.new do |value|; ":#{value}" end)
      end

      path '/CreateDistributive',
        'создания комплекта поставки в указанном каталоге' do
        path_exist '-File', 'имя файла описания комплекта поставки'
        string '-Option','вариант поставки'
        switch '-Make', 'создать',
          switch_list: switch_list(
          Setup: 'комплект поставки (используется по умолчанию)',
          Files: 'файлы поставки'
          )
        path_exist '-digisign', 'файл с параметрами лицензирования'
      end
      flag '/ResetMasterNode', 'сброс главного узла РИБ'
      flag '/CheckConfig',
        'централизованная проверка конфигурации' do
        flag '-ConfigLogIntegrity',
          'проверка логической целостности конфигурации'
        flag '-IncorrectReferences',
          'поиск некорректных ссылок, поиск ссылок на удаленные объекты'
        flag '-ThinClient',
          'синт. контроль модулей для режима управляемого приложения'\
          ' (тонкий клиент), выполняемого в файловом режиме'
        flag '-WebClient', 'синт. контроль модулей в режиме веб-клиента'
        flag '-Server', 'синт. контроль модулей в режиме сервера 1С:Предприятия'
        flag '-ExternalConnection',
          'синт. контроль модулей в режиме внешнего соединения,'\
          ' выполняемого в файловом режиме'
        flag '-ExternalConnectionServer',
          'синт. контроль модулей в режиме внешнего соединения,'\
          ' выполняемого в клиент-серверном режиме'
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
        flag '-DistributiveModules',
          'проверяется возможность генерации модулей без исходных текстов'
        flag '-UnreferenceProcedures', 'поиск неиспользуемых процедур и функций'
        flag '-HandlersExistence',
          'проверка существования назначенных обработчиков'
        flag '-EmptyHandlers', 'поиск пустых обработчиков'
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
        path_exist '–digisign', 'файл с параметрами лицензирования'
      end
    end
  end
end
