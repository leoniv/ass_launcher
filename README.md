[![Code Climate](https://codeclimate.com/github/leoniv/ass_launcher/badges/gpa.svg)](https://codeclimate.com/github/leoniv/ass_launcher)
[![Gem Version](https://badge.fury.io/rb/ass_launcher.svg)](https://badge.fury.io/rb/ass_launcher)
[![Inline docs](http://inch-ci.org/github/leoniv/ass_launcher.png)](http://inch-ci.org/github/leoniv/ass_launcher)
[![Build Status](https://travis-ci.org/leoniv/ass_launcher.svg?branch=master)](https://travis-ci.org/leoniv/ass_launcher)

_English version of README is [here](en.README.md)_

# AssLauncher

[Gem *AssLauncher*](https://rubygems.org/gems/ass_launcher) - это обертка поверх
платформы 1С:Предприятие v8 написанная на языке [Ruby](http://ruby-lang.org).

Цель *AssLauncher* - дать в руки "1С программистам" очень мощный, гибкий,
простой и лаконичный язык Ruby для того, чтобы их работа стала приятнее и
продуктивнее. Наслаждайтесь вместе с Ruby :)

## Введение в проблему

Те кто писал скрипты на cmd знают какое это унылое занятие. Те кто писал скрипты
на cmd для запуска платформы 1С, с той или иной целью, знают, что это занятие
[еще более унылое](https://github.com/leoniv/v8_circles_of_hell/blob/master/articles/круг_первый_скриптинг.md)
чем первое. И практически никто, кто писал такие скрипты, не
пытался закладывать в них требование переносимости между машинами.

## Назначение

*AssLauncher* это библиотека предоставляющая базовый набор абстракций для
удобного и надежного доступа к платформе 1С из языка Ruby.
*AssLauncher* берет на себя разрешение путей, поиск исполняемых файлов платформы
1С и прочую рутину без которой сложно создавать надежное и переносимое между
системами ПО.

Эти абстракции можно разделить на две группы. Первая группа предназначена для
запуска исполняемых файлов платформы 1С:Предприятие в различных вариантах работы
с различными наборами параметров.

Вторая группа предназначена для доступа к 1С рантайму и кластеру серверов 1С
по средствам OLE(Com) серверов предоставляемых платформой 1С.

## Область применения

В общем случае это создание программ на Ruby которые делают некоторые полезные
штуки с приложениями 1С. На пример:

- скрипты автоматизации административных задач сопровождения 1С приложений
- вынос части бизнес/интеграционной логики из 1С приложения на строну Ruby
- утилиты автоматизации процесса разработки 1С приложений
- создание автоматизированных тестов тестирующих 1С приложения

В настоящее время на базе *AssLauncher* разрабатывается набор библиотек имеющих
общую идею имя которой
[Ruby Powered Workflow](https://github.com/leoniv/ruby_powered_workflow)

## Зависимости

*AssLauncher* проектировался как кросс-платформенный инструмент. Однако, та
часть *AssLauncher*, которая относится к доступу к платформе 1С через OLE(Com)
сервер предназначена только для Windows. Более того, в настоящее время, возможна
работа только с 32х разрядными OLE серверами 1С из 32х разрядного Ruby.

_Ниже будут описаны проблемы связанные с использованием 64x разрядных 1С OLE
серверов._

Рекомендуемое окружение:

- OC Widows старше Windows XP
- UNIX окружение [cygwin](https://www.cygwin.com). Используйте 32-х разрядный
вариант установки cygwin [setup-x86.exe](https://www.cygwin.com/setup-x86.exe)
- установленный в cygwin 32-х разрядный Ruby версии старше 2.0

## Использование

Основной вариант использования *AssLauncher* это набор классов.

Однако с версии `0.3.0`, *AssLauncher* в дополнение к набору классов,
предоставляет консольную утилиту `ass-launcher` которая имеет следующие фичи:

- создание новых экземпляров приложений 1С известных как "информационная база"
- запуск платформы 1С в различных её вариантах таких как *thick/thin/web*
клиенты и *designer* он же *конфигуратор*
- показывает справку по CLI параметрам платформы 1С в различных её
вариантах таких как *thick/thin/web* клиенты и *designer* он же *конфигуратор*
- и кое-что еще см. `ass-launcher --help`

### Подключение к проекту

Стандартный способ с использованием менеджера зависимостей
[bundler](https://bundler.io):

1. добавить в [Gemfile](https://bundler.io/gemfile.html) следующую строку:

```ruby
gem 'ass_launcher'
```

2. запустить установку:

```
$ bundle
```

### Установка в систему

Стандартный способ установки gem-а:

```
$ gem install ass_launcher
```

После установки в gem-а в систему станет доступна утилита `ass-launcer`

```
$ ass-launcher --help
```

### Базовый Api

Базовый Api *AssLauncher* выделен в модуль `AssLauncher::Api`. Используйте этот
модуль как mixin.
[Документация по AssLauncher::Api](https://www.rubydoc.info/gems/ass_launcher/AssLauncher/Api)

### Быстрый пример

Для примера предлагается скрипт который выполняет дамп приложения (информационной
базы).

<details><summary>развернуть...</summary>
<p>

```ruby
require 'ass_launcher'

# Модуль предоставляет общий Api AssLauncher
include AssLauncher::Api

def main(dupm_path)
  # Получаем обертку для толстого клиента версии 8.3.8.+
  thick_client = thicks('~> 8.3.8.0').last

  # Если AssLauncher не смог найти исполняемый файл метод thicks вернет
  #  пустой массив, а пустой_массив.last вернет nil
  fail 'Установка платформы 1С v8.3.8 не найдена'\
       ' выполните `ass-launcher env` для просмотра установленных'
       ' версий платформы 1С' if thick_client.nil?

  # Создаем объект для запуска толстого клиента в режиме
  #  "конфигуратора" с необходимыми параметрами запуска:
  #   - _S - путь к серверной ИБ - параметр запуска /S
  #   - dumpIB dump_path - выполнение пакетной команды - параметр /DumpIB
  designer = thick_client.command :designer do
    _S 'enterprse_server/application_name'
    dumpIB dupm_path
  end

  # Запускам команду на исполнение и ждем завершения
  designer.run.wait

  # Проверяем результат. Если работа конфигуратора завершится с ошибкой
  #  verify! кинет исключение
  designer.process_holder.result.verify!
end

main ARGV[0]
```

</p></details>

Больше примеров можно найти в каталогах [examples/](examples/) и
[examples/troubles](examples/troubles)

## 1С:Предприятие x86_64 для Windows

С версии `8.3.9` 1С выпустила x86_64 дистрибутив платформы для Windows. Для
выбора архитектуры платформы `AssLauncher::Enterprise::BinaryWrapper` имеет
свойство `arch` по которому можно фильтровать массив найденных установок
платформы 1С. Однако для удобства в модуле `AssLauncher::Api` реализовано
несколько хелперов с суффиксами `*_i386` и `*_x86_64` которые возвращают уже
отфильтрованный по архитектуре массив.

Для in-process OLE сервера 1С `v83.ComConnector`, файл `comcntr.dll`, архитектура
бинарного файла сервера выбирается автоматически в зависимости от архитектуры
Ruby.

По умолчанию, использование x86_64 OLE сервера 1С, запрещено (из за проблем
описанных ниже). Для принудительного использования x86_64 OLE сервера 1С
установите флаг `use_x86_64_ole` конфига *AssLauncher*:

```ruby
  AssLauncher.configure do |conf|
    conf.use_x86_64_ole = true
  end
```

## Проблемы связанные с работой с OLE серверами 1С

### Проблема с x86_64 in-process OLE сервером `v83.COMConnector`

При использовании `x86_64` сервера `v83.COMConnector`, Ruby терпит крах при
возникновении исключения во время вызова метода сервера `connect`:
```
$ruby -v
ruby 2.3.6p384 (2017-12-14 revision 9808) [x86_64-cygwin]

$pry

RbConfig::CONFIG['arch'] #=> "x86_64-cygwin"

require 'win32ole'

inproc = WIN32OLE.new('V83.COMConnector')

inproc.connect('invalid connection string')

....*** buffer overflow detected ***: terminated
Aborted (стек памяти сброшен на диск)
```

Тот же пример для `i386` сервера работает прекрасно:

```
$ruby -v
ruby 2.3.6p384 (2017-12-14 revision 9808) [i386-cygwin]

$pry

RbConfig::CONFIG['arch'] #=> "i386-cygwin"

require 'win32ole'

inproc = WIN32OLE.new('V83.COMConnector')

inproc.connect('invalid connection string')

WIN32OLERuntimeError: (in OLE method `connect': )
    OLE error code:80004005 in V83.COMConnector.1
      Неверные или отсутствующие параметры соединения с информационной базой
    HRESULT error code:0x80020009
      Exception occurred.
from (pry):3:in `method_missing'
```

### Проблемы с x86_64 local OLE серверами `v83c.Application` и `v83.Application`

В теории архитектура local OLE сервера, в отличии от in-process сервера, не важна
с точки зрения архитектуры клиента, т.е. Ruby, так как local OLE сервер
выполняется в своем процессе.

Однако это только в теории. Если запустить [examples/](examples) в `i386` Ruby
но использовать `x86_64` серверы `v83.Application` наблюдается неожиданное
поведение такое как неизвестная ошибка при установке соединения с информационной
базой:

```
WIN32OLERuntimeError: (in OLE method `connect': )
    OLE error code:0 in <Unknown>
      <No Description>
    HRESULT error code:0x80010108
      The object invoked has disconnected from its clients.
    /tmp/ass_launcher/lib/ass_launcher/enterprise/ole/win32ole.rb:87:in `method_missing'
    /tmp/ass_launcher/lib/ass_launcher/enterprise/ole/win32ole.rb:87:in `call'
    /tmp/ass_launcher/lib/ass_launcher/enterprise/ole/win32ole.rb:87:in `block in <class:WIN32OLE>'
    /tmp/ass_launcher/lib/ass_launcher/enterprise/ole.rb:142:in `__try_open__'
    /tmp/ass_launcher/lib/ass_launcher/enterprise/ole.rb:136:in `__open__'
    /tmp/ass_launcher/examples/enterprise_ole_example.rb:131:in `block (4 levels) in <module:EnterpriseOle>'
```

## Получение помощи в работе с AssLauncher

Если у Вас есть вопросы откройте новый issue с меткой `question`.

## Разработка

### Документирование кода

Для документирования кода используется разметка [yadr](https://yardoc.org/)

### Поддержание *AssLauncher* в согласованном состоянии с релизами платформы 1С

Одна из основных фич *AssLauncher* это контроль корректности CLI параметров
консольного запуска платформы 1С. Для этого *AssLauncher* должен знать CLI
каждой поддерживаемой версии платформы 1С, для каждого режима запуска платформы.

В *AssLauncher* реализован специальный
[DSL](https://www.rubydoc.info/gems/ass_launcher/AssLauncher/Enterprise/Cli/SpecDsl)
описания CLI платформы 1С.

Само описание CLI платформы расположено в каталоге
[cli_def](lib/ass_launcher/enterprise/cli_def/) в котором для каждой
поддерживаемой версии платформы необходимо создать файл имя которого состоит из
трех старших номеров версии платформы и расширения `.rb` на пример `8.3.12.rb`.

В этом файле с помощью вышеупомянутого DSL надо описать **только изменения** CLI
которые произошли в данной версии платформы по сравнению с последней
поддерживаемой *AssLauncher* версией 1С.

Для того чтобы описать разницу в CLI текущей версии платформы и последней
поддерживаемой версией надо внимательно вычитать документацию по CLI двух этих
версий. Это очень нудное занятие которое можно автоматизировать.
На пример можно сохранить текст справки по CLI одной версии
платформы и поместить его под контроль git, затем сделать тоже самое с
документацией второй версии и посмотреть разницу с помощью `git diff`. Такая
идея уже имеет свою реализацию пригодную к использованию:
[help_to_text](https://github.com/leoniv/help_to_text)

Тема про использование DSL достаточно обширная и здесь затронута не будет,
однако сам DSL
[задокументирован](https://www.rubydoc.info/gems/ass_launcher/AssLauncher/Enterprise/Cli/SpecDsl),
а примеры использования можно посмотреть в каталоге `cli_def`.

Для помощи в описании CLI платформы можно использовать утилиту
[bin/dev-helper](bin/dev-helper) которая может создавать сниппеты DSL выводить
отчет и открывать конфигуратр:

    $ bin/dev-helper -v

### Тестирование

Для тестирования *AssLauncher* использует тестовый фреймворк
[Minitest](https://rubygems.org/gems/minitest). Тесты находятся в каталоге
[test/](test/). Все тесты в каталоге `test` являются Unit тестами и не требуют
наличия установленной платформы 1С. Этого принципа надо строго придерживаться в
будущем. В качестве интеграционных тестов выступают примеры использования
*AssLauncher* расположенные в каталоге [examples/](examples/).

Запуск тестов. После клонирования репозитория запустите установку зависимостей
`bin/setup` далее запустите тесты `bundler exec rake`. Так же вы можете запустить
`bin/console` и поиграть с AssLauncher в интерактивной оболочке
[Pry](https://github.com/pry/pry)

### Релиз

Стандартный процесс для [Gem](https://rubygems.org) пакета.

- обновить номер версии в `version.rb`
- запустить `bundle exec rake release` который создаст git tag для версии,
запушит commit и tag в репозиторий и запушит `.gem` файл на
[rubygems.org](https://rubygems.org)

## Поддержка

Bug reports and pull requests are welcome on GitHub at https://github.com/leoniv/ass_launcher.

