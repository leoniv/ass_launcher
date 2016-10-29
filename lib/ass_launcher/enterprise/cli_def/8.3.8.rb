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
#    fail 'FIXME'
#    switch '/AppAutoCheckVersion',
#           'определяет использование подбора нужной версии для каждой базы',
#           switch_list: switch_list(:+ => 'FIXME: description',
#                                    :- => 'FIXME: description')
#
  end

  group :packge_mode do
    mode :designer do
      #FIXME: path_twice 'DumpExternalDataProcessorOrReportToFiles'
    end
  end

end
