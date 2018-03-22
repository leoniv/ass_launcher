module AssLauncher::Enterprise::CliDef
  group :packge_mode do
    mode :designer do
      chose '/SetPredefinedDataUpdate', 'режим обновления предопределенных данных',
            chose_list:\
            chose_list(:"-Auto" => 'фактическое значение вычисляется автоматически',
              :"-UpdateAutomatically" => 'при реструктуризации информационной базы'\
              ' будет выполняться автоматическое создание предопределенных'\
              ' элементов и обновление существующих значений',
              :"-DoNotUpdateAutomatically" => 'при реструктуризации информационной'\
              ' базы не будет выполняться автоматическое создание предопределенных'\
              ' элементов и обновление существующих значений')
    end
  end

  group :repository do
    mode :designer do
      flag '/ConfigurationRepositoryCreate',
        'создание хранилища конфигурации' do
        flag '-AllowConfigurationChanges', 'включет возможность изменения'\
          ' конфигурации находящейся на поддержке'
        chose '-ChangesAllowedRule',
          'устанавливает правило поддержки для объектов для которых'\
          ' изменения разрешены поставщиком',
          chose_list:\
          chose_list(:ObjectNotEditable => 'объект не редактируется',
            :ObjectIsEditableSupportEnabled =>\
            'объект редактируется с сохранением поддержки',
            :ObjectNotSupported => 'объект снят с поддержки')
        chose '-ChangesNotRecommendedRule ',
          'устанавливает правило поддержки для объектов для которых'\
          ' изменения не рекомендуются поставщиком',
          chose_list:\
          chose_list(:ObjectNotEditable => 'объект не редактируется',
            :ObjectIsEditableSupportEnabled =>\
            'объект редактируется с сохранением поддержки',
            :ObjectNotSupported => 'объект снят с поддержки')
        flag '-NoBind',
          'не подключаться к созданному хранилищу'
      end

      flag '/ConfigurationRepositoryAddUser',
        'создание пользователя хранилища конфигурации' do
        string '-User', 'имя пользователя'
        string '-Pwd', 'пароль пользователя'
        chose 'Rights', 'Права пользователя',
              chose_list:\
              chose_list(:ReadOnly => 'просмотр',
                :LockObjects => 'захват объектов',
                :ManageConfigurationVersions => 'изменение состава версий',
                :Administration => 'административные функции')
        flag '-RestoreDeletedUser',
          'удаленный пользователь с таким же именем будет восстановлен'
      end
    end
  end

  skip '/ConfigurationRepositoryCopyUsers'
end
