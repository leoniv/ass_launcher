[![Code Climate](https://codeclimate.com/github/leoniv/ass_launcher/badges/gpa.svg)](https://codeclimate.com/github/leoniv/ass_launcher)
[![Gem Version](https://badge.fury.io/rb/ass_launcher.svg)](https://badge.fury.io/rb/ass_launcher)

_English version of README is [here](README.en.md)_

# AssLauncher

*AssLauncher* это обертка для платформы 1С:Предприятие v8 написанная на языке
[Ruby](http://ruby-lang.org) как [gem](https://rubygems.org) пакет.

Зачем нужна такая обертка? Если коротко - цель *AssLauncher* это помощь при
создании утилит автоматизации процессов разработки и сопровождения ПО для
платформы 1С:Предприятие на очень мощном, гибком, простом и лаконичном языке
Ruby.

*AssLauncher* берет на себя рутину связанную, на пример, с разрешением путей к
бинарным файлам платформы, и не только её, что делает разработку таких утилит
более приятным и продуктивным занятием.

Основной вариант использования *AssLauncher* это набор классов
для использования в Ruby скриптах, однако с версии `0.3.0`, *AssLauncher* в
дополнение к набору классов, предоставляет консольную утилиту `ass-launcher`.

## Зависимости

*AssLauncher* проектировался как кросс-платформенный инструмент. Однако, та
часть *AssLauncher*, которая относится к доступу к платформе 1С через OLE(Com)
сервер, будет работать только в ОС Windows. Подробности про использование OLE
фичи *AssLauncher* и связанные с этим проблемы описаны в соответствующем разделе.

Рекомендуемое окружение:

- OC Widows старше Windows XP
- UNIX окружение [cygwin](https://www.cygwin.com). Используйте 32-х разрядный
вариант установки cygwin [setup-x86.exe](https://www.cygwin.com/setup-x86.exe)
- установленный в cygwin 32-х разрядный Ruby версии старше 2.0

## Подключение к проекту

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

## Установка в систему

Стандартный способ установки gem-а:

```
$ gem install ass_launcher
```

После установки в gem-а в систему станет доступна утилита `ass-launcer`

```
$ ass-launcher help
```
