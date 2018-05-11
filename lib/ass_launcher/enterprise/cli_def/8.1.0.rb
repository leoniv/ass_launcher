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

  skip '/@'
  skip '/AU'
  skip '/IBConnectionString'

end

