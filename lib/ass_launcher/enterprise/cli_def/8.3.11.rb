module AssLauncher::Enterprise::CliDef
  restrict '/TESTCLIENT'

  group :debug do
    mode :webclient, :enterprise do
      flag '/TESTCLIENT',
        'запуск в качестве объекта автоматизированного тестирования.'\
        ' Для идентификации конкретного экземпляра веб-клиента следует'\
        ' использовать параметр TestClientID' do
          num '-TPort', 'Номер TCP порта. По умолчанию 1538'\
            ' Не используется в вэб-клиенте!'
      end
    end
  end

  group :packge_mode do
    mode :designer do
      change '/CheckConfig' do
        flag '-CheckUseSynchronousCalls', 'проверять синхронные вызовы'
      end
    end
  end
end
