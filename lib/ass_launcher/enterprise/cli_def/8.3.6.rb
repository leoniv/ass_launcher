module AssLauncher::Enterprise::CliDef
  group :packge_mode do
    mode :designer do
      change '/DumpCfg' do
        string '-Extension', 'обработка расширения с указанным именем'
      end
      change '/LoadCfg' do
        string '-Extension', 'обработка расширения с указанным именем'
      end
      change '/UpdateDBCfg' do
        switch '-Dynamic', 'признак использования динамического обновления',
               switch_list:\
               switch_list(
                 :+ => 'значение по умолчанию. Сначала выполняется попытка'\
                 ' динамического обновления, если она завершена неудачно,'\
                 ' будет запущено фоновое обновление',
                 :- => 'динамическое обновление запрещено')
        flag '-BackgroundStart',
          'будет запущено фоновое обновление конфигурации и завершение работы' do
          switch '-Dynamic', 'признак использования динамического обновления',
                 switch_list:\
                 switch_list(
                   :+ => 'значение по умолчанию. Сначала выполняется попытка'\
                   ' динамического обновления, если она завершена неудачно,'\
                   ' будет запущено фоновое обновление',
                   :- => 'динамическое обновление запрещено')
        end
        flag '-BackgroundCancel',
          'отменяет запущенное фоновое обновление конфигурации базы данных'
        flag '-BackgroundFinish',
          'запущенное фоновое обновление конфигурации базы данных будет завершено' do
          flag '-Visible', 'на экран будет выведен диалоговое окно,'\
            ' если не указан, выполнение обновления будет завершено с ошибкой'
          flag '-WarningsAsErrors',
            'все предупредительные сообщения трактуются как ошибки'
        end
        flag '-BackgroundSuspend',
          'приостанавливает фоновое обновление конфигурации'
        flag '-BackgroundResume',
          'продолжает фоновое обновление конфигурации'
        string '-Extension',
          'будет выполнено обновление расширения с указанным именем'
      end
      change '/DumpDBCfg' do
        string '-Extension', 'обработка расширения с указанным именем'
      end
      change '/RollbackCfg' do
        string '-Extension', 'обработка расширения с указанным именем'
      end
      flag '/DeleteCfg', 'удаление расширений конфигурации' do
        string '-Extension', 'обработка расширения с указанным именем'
        flag '-AllExtensions', 'удаление всех расширений'
      end
      flag '/DumpDBCfgList', 'вывод расширений конфигурации' do
        string '-Extension', 'обработка расширения с указанным именем'
        flag '-AllExtensions', 'обработка всех расширений'
      end
      change '/CheckModules' do
        string '-Extension', 'обработка расширения с указанным именем'
        flag '-AllExtensions', 'обработка всех расширений'
      end
      change '/CheckConfig' do
        string '-Extension', 'обработка расширения с указанным именем'
        flag '-AllExtensions', 'обработка всех расширений'
      end
      change '/LoadConfigFromFiles' do
        string '-Extension', 'обработка расширения с указанным именем'
        flag '-AllExtensions', 'обработка всех расширений'
      end
      change '/DumpConfigToFiles' do
        string '-Extension', 'обработка расширения с указанным именем'
        flag '-AllExtensions', 'обработка всех расширений'
      end
    end
  end

  group :repository do
    mode :designer do
      flag '/ConfigurationRepositoryBindCfg',
        'подключение неподключенной конфигурации к хранилищу' do
        flag '-forceBindAlreadyBindedUser',
          'подключение будет выполнено даже в случае, если для данного'\
          ' пользователя уже есть конфигурация, связанная с данным хранилищем'
        flag '-forceReplaceCfg',
          'если конфигурация не пустая, текущая конфигурация'\
          ' будет заменена конфигурацией из хранилища'
      end
    end
  end

end
