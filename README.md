# AssLauncher

Ruby wrapper for 1C:Enterprise platform. Don't ask why this necessary. Believe this necessary!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ass_launcher'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ass_launcher

## Usage

For example:

```ruby
require 'ass_launcher'

include AssLauncher::API

#
# Get 1C:Enterprise v8.3.7 binary wrapper
#

cl = thick_clients('~> 8.3.7').last

raise '1C:Enterprise v8.3.7 not found' if cl.nil?

#
# create new infobase
#

conn_str = connection_string 'File="./new.ib"'

ph = cl.command(:createinfobase) do
  connection_string conn_str
  _AddInList
end.run.wait

raise 'Error while create infobase' if ph.result.success?

#
# dump infobase
#

command = cl.command(:designer) do
  connection_string 'File="./new.ib"'
  _DumpIB './new.ib.dt'
end

ph = command.run
ph.wait

ph.result.verify! # raised error unless executing success

#
# run designer for development
#

ph = cl.command(:designer) do
  connection_string 'File="./new.ib"'
end.run

# .... do in designer

ph.kill # kill designer

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/leoniv/ass_launcher.

