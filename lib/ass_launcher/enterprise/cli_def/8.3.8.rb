module AssLauncher::Enterprise::CliDef
  group :other do
    restrict '/L'
    mode :enterprise, :designer, :webclient, :createinfobase do
      string '/L', 'указывается код языка интерфейса платформы:'\
        ' ru - Русский, en - Английский и т.д. Список см. в документации 1С'
    end

    mode :enterprise, :webclient, :createinfobase do
      restrict '/VL'
      string '/VL', 'код локализации сеанса'
    end

    mode :enterprise do
      flag '/EnableCheckExtensionsAndAddInsSyncCalls',
        'включает режим строгой проверки использования синхронных вызовов'
    end
  end

  group :connection do
    mode :enterprise, :designer do
      restrict '/AppAutoCheckVersion'
      switch '/AppAutoCheckVersion',
             'определяет использование подбора нужной версии для каждой базы',
             switch_list: switch_list(:+ => 'выполняется',
                                      :- => 'не выполняется')
    end
  end

  group :packge_mode do
    mode :designer do
      path_twice '/DumpExternalDataProcessorOrReportToFiles',
        'выгрузка внешних обработок или отчетов в xml файлы' do
        chose '-Format',
          'формат выгрузки файлов',
              chose_list:\
              chose_list(:Hierarchical => 'иерархический формат. По умолчанию',
                         :Plain => 'линейный формат')
      end
      path_twice '/LoadExternalDataProcessorOrReportFromFiles',
        'загрузка внешних обработок или отчетов из xml файлов'
      path_exist '/MergeCfg',
        'объединение текущей конфигурации с файлом, используя файл настроек' do
        path_exist '-Settings', 'путь к файлу настроек объединения'
        flag '-EnableSupport',
          'текущая конфигурация будет поставлена на поддержку при объединении.'\
          ' Правила поддержки должны быть указаны в файле настроек'
        flag '-DisableSupport',
          'текущая конфигурация не будет поставлена на поддержку'
        flag '-IncludeObjectsByUnresolvedRefs',
          'автоматическое включение объектов метаданных в список объединения'\
          ' по ссылкам если эти объекты не указаны явно для объединения'
          ' в файле настроек'
        flag '-ClearUnresolvedRefs', 'очистка ссылок на объекты метаданных'\
          ' если эти объекты не указанны для объединения в файле настроек'
        flag '-Force', 'объединение будет выполнено не смотря на наличие'\
          ' предупреждений о применении настроек и об удаляемых объектах,'\
          ' на которые найдены ссылки в объектах, не участвующие в объединении'\
      end
      change '/UpdateCfg' do
        flag '-IncludeObjectsByUnresolvedRefs',
          'автоматическое включение объектов метаданных в список обновления'\
          ' по ссылкам если эти объекты не указаны явно для обновления'
          ' в файле настроек'
        flag '-ClearUnresolvedRefs', 'очистка ссылок на объекты метаданных'\
          ' если эти объекты не указанны для обновления в файле настроек'
        flag '-Force', 'объединение будет выполнено не смотря на наличие'\
          ' предупреждений о применении настроек, дважды измененных свойствах,'\
          ' для которых не был выбран режим объединения, об удаляемых объектах,'\
          ' на которые найдены ссылки в объектах, не участвующие в объединении'
        flag '-DumpListOfTwiceChangedProperties',
          'вывести список всех дважды измененных свойств'
      end
    end
  end

  group :repository do
    mode :designer do
      flag '/ConfigurationRepositoryCommit',
        'помещение изменений объектов в хранилище конфигурации' do
        path_exist '-Objects',
          'путь к файлу формата XML со списком объектов, если опущен будут'\
          ' будут помещены изменения всех объектов конфигурации'
        string '-Comment', 'комментарий'
        flag '-KeepLocked', 'оставлять захват для помещенных объектов'
        flag '-Force',
          'при обнаружении ссылок на удаленные объекты будет выполнена'\
          ' попытка их очистить'
      end
      flag '/ConfigurationRepositoryLock',
        'захват объектов для редактирования в хранилище конфигурации' do
        path_exist '-Objects', 'путь к файлу формата XML со списком объектов,'\
          ' если опущен будут захвачены все объекты конфигурации'
        flag '-Revised', 'получать захваченные объекты'
      end
      flag '/ConfigurationRepositorySetLabel',
        'установка метки для версии хранилища' do
        string '-v', 'номер версии', required: true
        string '-Name', 'имя метки',
          required: true,
          value_validator: proc {|value| "\"#{value}\""}
        string '-Comment', 'комментарий. Чтобы установить многострочный'\
          ' комментарий, для каждой строки следует использовать свою опцию'\
          ' -Comment',
          value_validator: proc {|value| "\"#{value}\""}
      end
      change '/ConfigurationRepositoryUpdateCfg' do
        path_exist '-Objects', 'путь к файлу формата XML со списком объектов,'\
          ' если опущен будут обновлены все объекты конфигурации'
      end
      flag '/ConfigurationRepositoryUnlock',
        'отмена захвата объектов для редактирования в хранилище конфигурации' do
        path_exist '-Objects', 'путь к файлу формата XML со списком объектов,'\
          ' если опущен будет отменен захват всех объектов конфигурации'
        flag '-Force',
          'если не указана, то при наличии локально измененных объектов'\
          ' будет выдана ошибка'
      end
    end
  end
end
