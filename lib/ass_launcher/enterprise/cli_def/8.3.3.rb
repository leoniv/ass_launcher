module AssLauncher::Enterprise::CliDef
  group :other do
    mode :enterprise, :designer, :createinfobase do
      flag('/DisableStartupDialogs', 'подавляет gui диалоги')
    end

    mode :enterprise, :webclient do
      flag '/iTaxi', 'режим интерфейса "Такси"'
    end

    mode :enterprise do
      chose '/AllowExecuteScheduledJobs',
        'управление запуском регламентных заданий для файловой информационной базы',
         chose_list: chose_list(:"-Off" => 'задания отключены для текущего сеанса',
                                :"-Force" => 'задания в текущем сеансе будут выполнятся не смотря а то, что уже есть сеанс в котром выполняются задания')
    end
  end

  group :debug do
    mode :webclient do
      string '/TESTCLIENTID',
        'запуск в качестве объекта автоматизированного тестирования.'\
        ' Если значение идентификатора не указано или запущено несколько'\
        ' клиентов с одним и тем же значением, то выбирается произвольный.'
    end

    mode :enterprise do
      flag '/TESTMANAGER',
        'запуск в качестве менеджера автоматизированного тестирования'
      flag '/TESTCLIENT',
        'запуск в качестве объекта автоматизированного тестирования' do
        num '-TPort', 'номер TCP порта. По умолчанию 1538'
      end
      flag '/UILOGRECORDER',
        'запись журнала интерактивных действий пользователя.'\
        ' Может совмещаться с параметром /TESTCLIENT' do
        num '-TPort', 'номер TCP порта. По умолчанию 1538'
        path '-File', 'журнал действий пользователя'
      end
    end
  end

  group :packge_mode do
    mode :designer do
      flag '/MAUpdatePublication', 'обновление публикации мобильного приложения'
      path '/MAWriteFile', 'записывает xml файл мобильного приложения'
      change '/CheckModules' do
        flag '-MobileAppClient', 'в контексте клиента моб. приложения'
        flag '-MobileAppServer', 'в контексте сервера моб. приложения'
        flag '-ExtendedModulesCheck', 'расширенная проверка'
      end

      change '/CheckConfig' do
        flag '-MobileAppClient',
          'синт. контроль модулей в режиме клиента мобильного приложения'
        flag '-MobileAppServer',
          'синт. контроль модулей в режиме сервера мобильного приложения'
        flag '-CheckUseModality',
          'поиск методов связанных с модальностью используется'\
          ' с ключом -ExtendedModulesCheck'
        flag '-UnsupportedFunctional',
          'поиск функциональности которая не может быть выполнена'\
          ' в мобильном приложении'
      end

      path '/DumpConfigToFiles',
        'выгрузка конфигурации в XML файлы'
      path_exist '/LoadConfigFromFiles',
        'загрузка конфигурации из XML файлов'
      flag '/EraseData',
        'удаление данных информационной базы. Параметром /Z можно задать область'
    end
  end

  group :repository do
    mode :designer do
      flag '/ConfigurationRepositoryOptimizeData',
        'оптимизация базы данных хранилища конфигурации'
      flag '/ConfigurationRepositoryClearCache',
        'очистка локальной базы данных хранилища конфигурации'
    end
  end

  skip '/OIDA'
  skip '/Authoff'
  skip '/HttpsCert'
  skip '/HttpsCA'
  skip '/HttpsNSS'
  skip '/AppAutoInstallLastVersion'
end
