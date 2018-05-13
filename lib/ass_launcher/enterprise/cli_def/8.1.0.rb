module AssLauncher::Enterprise::CliDef
  group :connection do
    mode :enterprise, :designer do
      path_exist '/F', 'путь к файловой информационной базе'
      string '/S', 'адрес серверной информационной базы. Вид "host:port/ibname"'
    end
  end

  group :authentication do
    mode :enterprise, :designer, :webclient do
      string '/N', 'имя пользователя информационной базы'
      string '/P', 'пароль пользователя информационной базы'
    end

    mode :enterprise, :designer, :webclient do
      switch '/WA',
        'аутентификация средствами операционной системы. Если не указано'\
        ' используется /WA+', thin, web,
        switch_list: switch_list(
          :+ => 'обязательное применение',
          :- => 'запрет применения'
        )
    end

    mode :enterprise do
      flag '/SAOnRestart', 'запрос пароля при перезапуске системы'
    end
  end

  group :debug do
    mode :enterprise, :webclient do
      url '/DebuggerURL', 'url отладчика'
    end

    mode :enterprise do
      flag '/Debug', 'запуск 1С:Предприятия в отладочном режиме'
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
                 ' Выводятся служебные сообщения и сообщения метода Сообщить()',
                thick)
      flag('/DisableStartupMessages', 'подавляет gui сообщения')
    end

    mode :enterprise, :designer, :webclient do
      string '/L', 'указывается код языка интерфейса платформы:'\
        ' ru - Русский, en - Английский и т.д. Список см. в документации 1С'
    end

    mode :enterprise, :designer do
      string '/UC', 'код для установки соединения с заблокированной базой'
      path_exist '/RunShortcut',
        'позволяет запустить систему со списком баз из указанного файла v8i'
    end

    mode :enterprise, :webclient do
      string '/C', 'передача строкового значения в экземпляр 1С приложения.'\
        ' Значение доступно в глобальной переменной `ПараметрЗапуска`.'\
        ' Использовать в строке двойные кавычки запрещено работает криво.',
        value_validator: (Proc.new do |value|
          fail ArgumentError,
            'In /C parameter double quote char forbidden for use' if /"/ =~ value
        end)
      switch '/SLev', 'определяет уровень защищенности соединения с сервером',
        switch_list: switch_list(:'0' => '',
                                 :'1' => '',
                                 :'2' => ''
                                )

    end

    mode :enterprise do
      path_exist '/Execute', 'запуска внешней обработки в режиме'\
        ' 1С:Предприятие непосредственно после старта системы'
      flag '/LogUI', 'логирование действий пользователя'
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
      path '/DumpDBCfg', 'сохранение конфигурации базы данных в файл'
      flag '/RollbackCfg', 'возврат к конфигурации базы данных'
      flag '/CheckModules', 'синт. контроль' do
        flag '-ClientServer', 'в режиме клиентского приложения'
        flag '-ExternalConnectionServer', 'проверка логической целостности'
        flag '-Server', 'в режиме сервера'
      end
      path_exist '/UpdateCfg', 'обновление конфигурации находящейся на'\
        ' поддержке из .cf или .cfu файла'
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
      flag '/ResetMasterNode', 'сброс главного узла РИБ'
      flag '/CheckConfig', 'централизованная проверка конфигурации' do
        flag '-ClientServer', 'проверка работы в режиме клиент-сервер'
        flag '-Client', 'проверка работы режиме клиент.'
        flag '-ExternalConnection',
          'синт. контроль модулей в режиме внешнего соединения,'\
          ' выполняемого в файловом режиме'
        flag '-ExternalConnectionServer',
          'синт. контроль модулей в режиме внешнего соединения,'\
          ' выполняемого в клиент-серверном режиме'
        flag '-Server', 'синт. контроль модулей в режиме сервера 1С:Предприятия'
        flag '-DistributiveModules',
          'проверяется возможность генерации модулей без исходных текстов'
        flag '-IncorrectReferences',
          'поиск некорректных ссылок, поиск ссылок на удаленные объекты'
        flag '-ConfigLogicalIntegrity', 'проверка логической целостности конфигурации'
        flag '-UnreferenceProcedures', 'поиск неиспользуемых процедур и функций'
        flag '-HandlersExistence',
          'проверка существования назначенных обработчиков'
        flag '-EmptyHandlers', 'поиск пустых обработчиков'
      end
      string '/ReduceEventLogSize', 'сокращение журнала регистрации,'\
        ' дата в формате ГГГГ-ММ-ДД', value_validator: (Proc.new do |value|
            fail ArgumentError,
              "Use format YYYY-MM-DD for /ReduceEventLogSize parameter. Given"\
              " `#{value}'" if /\A\d{4}-\d{2}-\d{2}\z/ =~ value
          end) do
        path '-saveAs', 'файл для сохранения копии удаляемых записей'
        flag '-KeepSplitting',
          'требуется сохранить разделение на файлы по периодам'
      end
      path '/DumpConfigFiles', 'выгрузка свойств объектов МД'\
        ' конфигурации в файлы' do
        flag '-Module', 'выгружать тексты модулей'
        flag '-Template', 'выгружать шаблоны'
        flag '-Help', 'выгружать справочную информацияю'
        flag '-AllWritable', 'выгружать только доступные на запись объекты'
      end
      path '/LoadConfigFiles', 'загрузка свойств объектов МД'\
        ' конфигурации из файлов выгруженных командой /DumpConfigFiles' do
        flag '-Module', 'загружать тексты модулей'
        flag '-Template', 'загружать шаблоны'
        flag '-Help', 'загружать справочную информацияю'
        flag '-AllWritable', 'загружать только доступные на запись объекты'
      end
      path '/CreateTemplateListFile',
        'создание файла шаблонов конфигураций в указанном файле' do
        flag '-TemplatesSourcePath',
          'путь для поиска файлов шаблонов конфигураций'
      end
      path '/ConvertFiles', 'конвертация бинарных файлов платформы'
      flag '/Visible',
        'делает исполнение пакетной команды видимым пользователю'
    end
  end

  group :distribution do
    mode :designer do
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
    end
  end

  skip '/@'
  skip '/AU'
  skip '/IBConnectionString'
  skip '/RunEnterprise'
  skip '/DumpResult'

end

