module AssLauncher::Enterprise::CliDef
  group :other do
    mode :enterprise, :webclient do
      flag('/DisplayUserNotificationList', 'показать непрочитанные сообщения')
    end
  end

  skip '/OidcSelectedProvider'
end
