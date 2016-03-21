# Здесь описана спецификация параметров cli запуска 1С:Предприятие
# Код этого файла выполняется в контексте объекта имеющего интерфейс
# модуля AssLauncher::Enterprise::Cli::Dsl

# Параметры определяются для режимов запуска платформы и разбиваются на группы.
# Режимы запуска определены в AssLauncher::Enterprise::Cli::DEFINED_MODES
# Группы определяются в этом модуле вызовом define_group
# 
# Определение параметра производится вызовом методов string, parh и т.д завернутых в блоки
# @example
#  mode :name do #Параметры для заданных режимов запуска 1С:Предприятие
#    group :name do #Добавляет параметры в указанную группу
#      #определение параметра cli
#    end
#  end
#
# Группы параметров определяют группу описывают группу и задают приоритет группы
# параметров для формирования справочной информации
# @example
#  define_group :grou_name, 'grop description', 10 # => grou_name: {desc: 'grop description', priority: 10}

# ==== Описание режимов запуска ====

describe_mode :enterprise, 'Запуск в режиме предприятия', 'ENTERPRISE [parameters]'
describe_mode :designer, 'Запуск в режиме конфигуратора', 'DESIGNER [parameters]'
describe_mode :createinfobase, 'Создание информационной базы', 'CREATEINFOBASE <connection_string> [parameters]'

# ==== Определения групп параметров ====

define_group :connection, 'Соединение с информационной базой', 0
define_group :authentication, 'Авторизация пользователя информационной базы', 10
define_group :debug, 'Отладка и тестирование', 30
define_group :packge_mode, 'Пакетный режим конфигуратора', 40
define_group :repository, 'Работа с хранилищем конфигурации', 50
define_group :distribution, 'Cоздание файлов поставки и обновления', 60
define_group :other, 'Прочие', 100

# ==== Определения параметров ====

mode :createinfobase do
  group :other do
    path '/UseTemplate', 'создание информационной базы на основе дампа (.dt файл) или конфигурации (.cf файл)'
    string '/AddInList', 'имя под которым надо добавить базу в пользовательский файл .v8i'
  end
end

mode :enterprise, :designer, :createinfobase do
  group :other do
    reserved 'use option :capture_assout => false for didn\'t capture 1C output', path('/Out', 'файл используемый 1С вместо stdout и stderr. В файл выводятся служебные сообщения, а также сообщения метода Сообщить()')
    reserved 'use option :silent_mode => false for enable gui dialogs', flag('/DisableStartupDialogs', 'подавляет gui диалоги') 
    reserved 'use option :silent_mode => false for enable gui messages', flag('/DisableStartupMessages', 'подавляет gui сообщения')
  end
end

mode :enterprise, :designer do
  group :connection do
    path '/F', 'путь к файловой информационной базе'
    string '/S', 'адрес информационной базы, хранящейся на сервере "1С:Предприятие 8". Имеет вид "host:port/ib_name"'
  end
  
  group :authentication do
    string '/N', 'имя пользователя информационной базы'
    string '/P', 'пароль пользователя информационной базы'
  end

  group :other do
    switch '/UseHwLicenses', 'определяет режим поиска локального ключа защиты', switch_list: switch_list(:"+" => 'поиск выполняется', :"-" => 'поиск не выполняется')
    string '/L', 'указывается код языка интерфейса платформы: ru - Русский, en - Английский, uk - Украинский и т.д. Полный список см. в документации 1С'
    skip '/RunShortcut', 'позволяет запустить систему со списком баз из указанного файла v8i'
    string '/Z', 'установка разделителей', all_client('>= 8.2.17')
  end
end

mode :enterprise do
  group :connection do
    url '/WS', 'url соединения c базой опубликованной через web сервер', thin_client('>= 8.2')
    flag '/SAOnRestart', 'указывает на обязательность запроса пароля при перезапуске системы из данного сеанса работы'
    flag '/NoProxy', 'запретить использование прокси', thin_client('>= 8.2')
    flag '/Proxy', 'использовать указанные настройки прокси', thin_client('>= 8.2') do
      url '-PSrv', 'адрес прокси', required: true
      num '-PPort', 'порт прокси', required: true
      string '-PUser', 'имя пользователя прокси'
      string '-PPwd', 'имя пользователя прокси'
    end   
  end

  group :authentication do
    switch '/WA', 'аутентификация средствами операционной системы', switch_list: switch_list(:"+" => 'обязательное применение (значение по умолчанию)', :"-" => 'запрет применения')
    skip '/WSA'
    string '/WSN', 'имя пользователя для аутентификации на веб-сервере', thin_client('>= 8.2')
    string '/WSP', 'пароль пользователя для аутентификации на веб-сервере', thin_client('>= 8.2')
  end

  group :other do
    chose  '/O', 'определяет скорость соединения', thin_client('>= 8.2'), chose_list: chose_list(Normal: 'обычная', Low: 'низкая')
    skip '/AppAutoCheckVersion'
    skip '/AppAutoCheckMode'
    skip '/LogUI'
    string '/VL', 'код локализации сеанса'
    string '/C', 'передача строкового значения в экземпляр 1С приложения.'
      ' Значение доступно в глобальной переменной `ПараметрЗапуска`.'
      ' Если в строке есть двойные кавычки работает криво.',
      value_validator: (Proc.new do |value|
        fail ArgumentError, "Use `\"' forbidden for /C parameter" if /"/ =~ value
      end)
    flag '/RunModeOrdinaryApplication', 'запуск толстого клиента в режиме обычного приложения  не зависимо от настроек', thick_client('>= 8.2')
    flag '/RunModeManagedApplication', 'запуск толстого клиента в режиме управляемого приложения  не зависимо от настроек', thick_client('>= 8.2')
    string '/UC', 'код доступа для установки соединения с заблокированной базой'  
    skip '/SLev'
    path '/Execute', 'запуска внешней обработки в режиме 1С:Предприятие непосредственно после старта системы'
    skip '/ClearCache'
    skip '/@'
    flag '/UsePrivilegedMode', 'запуск в режиме привилегированного сеанса'
    skip '/TComp'
    flag '/itdi', 'режим интерфейса с использованием закладок'
  end

  group :debug do
    flag '/Debug', 'запуск сессии отладки'
    url '/DebuggerURL', 'url отладчика'
  end
end
  
mode :designer do
  group :packge_mode do
    path '/DumpIB', 'выгрузка дампа информационной базы'
    path '/RestoreIB', 'загрузка информационной базы из дампа'
    path '/DumpCfg', 'сохранение конфигурации в файл'
    path '/LoadCfg', 'загрузка конфигурации из файла'
    flag '/UpdateDBCfg', 'обновление конфигурации базы данных' do
      flag '-WarningsAsErrors', 'все предупредительные сообщения трактуются как ошибки'
      flag '-Server', 'обновление будет выполняться на сервере'
    end
    path '/UpdateCfg', 'обновление конфигурации, находящейся на поддержке из .cf или .cfu файла'
    flag '/ConfigurationRepositoryUpdateCfg'
    skip '/DumpConfigFiles', 'выгрузка свойств объектов метаданных конфигурации'
    skip '/LoadConfigFiles', 'загрузка свойств объектов метаданных конфигурации'
    path '/DumpDBCfg', 'сохранение конфигурации базы данных в файл'
    flag '/RollbackCfg', 'возврат к конфигурации базы данных'
    flag '/CheckModules', 'синт. контроль' do
      flag '-ThinClient', 'в контексте тонкого клиента'
      flag '-WebClient', 'в контексте веб-клиента'
      flag '-Server', 'в контексте сервера'
      flag '-ExternalConnection', 'в контексте внешнего соединения'
      flag '-ThickClientOrdinaryApplication', 'в контексте толстого клиента'
    end

    flag '/IBCheckAndRepair', 'выполнить тестирование и исправление информационной базы' do
      flag '-ReIndex', 'реиндексация таблиц'
      flag '-LogIntegrity', 'проверка логической целостности' 
      flag '-LogAndRefsIntegrity', 'проверка логической и ссылочной целостности'
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
      flag '-UseStartPoint', 'использовать сохраненную точку возврата для продолжения тестирования с места, на котором оно было прервано'
      switch '-TimeLimit', 'ограничение максимального времени сеанса тестирования. Строка формата hhh:mm',
        value_validator: (Proc.new do |value|
        fail ArgumentError, "Use hhh:mm for -TimeLimit parameter but `#{value}' given" if /\A\d{1,3}:\d{2}\z/ =~ value
        end),
        switch_value: (Proc.new do |value|; ":#{value}" end)
    end

    path '/CreateDistributive', 'создания комплекта поставки в указанном каталоге' do
      path '-File', 'имя файла описания комплекта поставки'
      string '-Option','вариант поставки'
      switch '-Make', 'создать',
        switch_list: switch_list(
        Setup: 'комплект поставки (используется по умолчанию)',
        Files: 'файлы поставки'
        )
      path '-digisign', 'файл с параметрами лицензирования'
    end
    flag '/ResetMasterNode', 'сброс главного узла РИБ'
    flag '/CheckConfig', 'централизованная проверка конфигурации' do
      flag '-ConfigLogIntegrity', 'проверка логической целостности конфигурации'
      flag '-IncorrectReferences', 'поиск некорректных ссылок, поиск ссылок на удаленные объекты'
      flag '-ThinClient', 'синт. контроль модулей для режима управляемого приложения (тонкий клиент), выполняемого в файловом режиме'
      flag '-WebClient', 'синт. контроль модулей в режиме веб-клиента'
      flag '-Server', 'синт. контроль модулей в режиме сервера 1С:Предприятия'
      flag '-ExternalConnection', 'синт. контроль модулей в режиме внешнего соединения, выполняемого в файловом режиме'
      flag '-ExternalConnectionServer', 'синт. контроль модулей в режиме внешнего соединения, выполняемого в клиент-серверном режиме'
      flag '-ThickClientManagedApplication', 'синт. контроль модулей в режиме управляемого приложения (толстый клиент), выполняемого в файловом режиме'
      flag '-ThickClientServerManagedApplication', ' синт. контроль модулей в режиме управляемого приложения (толстый клиент), выполняемого в клиент-серверном режиме'
      flag '-ThickClientOrdinaryApplication', 'синт. контроль модулей в режиме обычного приложения (толстый клиент), выполняемого в файловом режиме'
      flag '-ThickClientServerOrdinaryApplication', 'синт. контроль модулей в режиме обычного приложения (толстый клиент), выполняемого в клиент-серверном режиме'
      flag '-DistributiveModules', 'проверяется возможность генерации образов модулей без исходных текстов'
      flag '-UnreferenceProcedures', 'поиск неиспользуемых процедур и функций'
      flag '-HandlersExistence', 'проверка существования назначенных обработчиков'
      flag '-EmptyHandlers', 'поиск пустых обработчиков'
      flag '-ExtendedModulesCheck', 'проверка обращений к методам и свойствам объектов "через точку" (для ограниченного набора типов)'
    end
    string '/ReduceEventLogSize', 'сокращение журнала регистрации, дата в формате ГГГГ-ММ-ДД',
    value_validator: (Proc.new do |value|
        fail ArgumentError, "Use ГГГГ-ММ-ДД for /ReduceEventLogSize parameter but `#{value}' given" if /\A\d{4}-\d{2}-\d{2}\z/ =~ value
      end) do
      path '-saveAs', 'файл для сохранения копии удаляемых записей'
      flag '-KeepSplitting', 'требуется сохранить разделение на файлы по периодам'
    end
    path '/CreateTemplateListFile', 'создание файла шаблонов конфигураций в указанном файле' do
      flag '-TemplatesSourcePath', 'путь для поиска файлов шаблонов конфигураций'
    end
    skip '/ConvertFiles', 'параметр пакетной конвертации файлов 1С:Предприятия 8.x'
    flag '/Visible', 'делает исполнение пакетной команды видимым пользователю'
    skip '/RunEnterprise', 'предназначен для запуска 1С:Предприятия после исполнения пакетной команды'
    skip '/DumpResult', 'предназначен для записи результата работы конфигуратора в файл'
  end
  
  group :repository do
    path '/ConfigurationRepositoryF', 'каталог хранилища'
    string '/ConfigurationRepositoryN', 'имя пользователя хранилища'
    string '/ConfigurationRepositoryP', 'пароль пользователя хранилища'
    path '/ConfigurationRepositoryDumpCfg', 'сохранить конфигурацию из хранилища в файл' do
      string '-v', 'номер версии хранилища'
    end
    path '/ConfigurationRepositoryUpdateCfg', 'обновить конфигурацию хранилища из хранилища' do
      string '-v', 'номер версии хранилища'
      flag '-revised', 'получать захваченные объекты, если потребуется'
      flag '-force', 'подтверждение получения новых или удаления существующих объектов конфигурации'
    end
    flag '/ConfigurationRepositoryUnbindCfg', 'отключение конфигурации от хранилища' do
      flag '-force', 'принудительное отключение от хранилища'
    end
    path '/ConfigurationRepositoryReport', 'построение отчета по истории хранилища' do
      string '-NBegin', 'номер версии начала отчета'
      string '-NEnd', 'номер версии окончания отчета'
      flag '-GroupByObject', 'с группировкой по объектам'
      flag '-GroupByComment', 'с группировкой по комментарию'
    end
  end
  
  group :distribution do
    flag '/CreateDistributionFiles', 'создание файлов поставки и обновления' do
      path '-cffile', 'создать дистрибутив (.cf файл)'
      path '-cfufile', 'создать обновление дистрибутива (.cfu файл)'
      path '-f', 'дистрибутив включаемый в обновление (.cf файл)'
      string '-v', 'версия дистрибутива включаемого в обновление'
      path '–digisign', 'файл с параметрами лицензирования'
    end
  end
end














