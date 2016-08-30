# encoding: utf-8
module AssLauncher::Enterprise::CliDef
  group :authentication do
    mode :enterprise, :designer, :webclient do
      string '/N', 'имя пользователя информационной базы'
      string '/P', 'пароль пользователя информационной базы'
    end

    mode :enterprise, :webclient do
      switch '/WA',
        'аутентификация средствами операционной системы', thin, web,
        switch_list: switch_list(
          :"+" => 'обязательное применение (значение по умолчанию)',
          :"-" => 'запрет применения'
        )
    end

    mode :enterprise do
      skip '/WSA'
      string '/WSN',
        'имя пользователя для аутентификации на веб-сервере', thin
      string '/WSP',
        'пароль пользователя для аутентификации на веб-сервере', thin
    end

    mode :webclient do
      switch '/OIDA', 'применение OpenID аутентификации ',
             switch_list: switch_list(
              :'+' => 'использовать OpenID-аутентификацию (по умолчанию)',
              :'-' => 'не использовать OpenID-аутентификацию'
      )
      flag '/Authoff', 'выполняет OpenID logout'
    end
  end
end
