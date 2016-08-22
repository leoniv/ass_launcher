[![Code Climate](https://codeclimate.com/github/leoniv/ass_launcher/badges/gpa.svg)](https://codeclimate.com/github/leoniv/ass_launcher)
# AssLauncher

Ruby wrapper for 1C:Enterprise platform. Don't ask why this necessary. Believe this necessary!

**Ruby ~> 2.0 require**

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

include AssLauncher::Api

#
# Get 1C:Enterprise ~> v8.3.7 binary wrapper
#

cl = thicks('~> 8.3.7').last

fail '1C:Enterprise ~> v8.3.7 not found' if cl.nil?

#
# create new infobase
#

conn_str = cs 'File="./tmp/new.ib"'

process_holder = cl.command(:createinfobase) do
  connection_string conn_str
  addInList 'New infobase'
end.run.wait

raise 'Error while create infobase' unless process_holder.result.success?

#
# dump infobase
#

command = cl.command(:designer) do
  connection_string 'File="./tmp/new.ib"'
  dumpIB './tmp/new.ib.dt'
end

ph = command.run.wait

ph.result.verify! # raised error unless executing success

#
# run designer for development
#

ph = cl.command(:designer) do
  connection_string 'File="./tmp/new.ib"'
end.run

# .... do in designer

ph.wait # wait while designer open

#
# Check config
#

result = cl.command(:designer) do
  connection_string 'File="./tmp/new.ib"'
  checkConfig do
    configLogIntegrity
    incorrectReferences
    thinClient
    unreferenceProcedures
  end
end.run.wait.result
result.verify!

#
# Web client
#

# Get web client instanse for connect to
# infobase 'http://host/port/path/infobase'
wc = web_client('http://host/path/infobase')

loc = wc.location do
  _N 'user_name'
  _P 'password'
  _L 'en'
end # => URI

# Or do it with uses connect string
connstr =  cs 'ws="http://host/path/infobase";usr="user";pwd="password"'
wc = web_client(connstr.uri)
loc = wc.location do
  _L 'en'
end # => URI

# And use given location URI with selenium driver:
# driver.navigate.to loc.to_s
```

## Releases

### 0.1.1.alpha
  - ```Cli::ArgumentsBuilder``` not implements
  - ```Cli::CliSpec``` require extracts in standalone ```gem```
  - ```WebClients``` not implements
  - ```API``` not implements
  - ```Support::``` stable
  - ```Enterprse``` stable
  - ```BinaryWrapper``` mostly stable, depends ```Cli::ArgumentsBuilder```
  - ```Enterprse::Ole``` stable

#### Small exaple:

```ruby
require 'ass_launcher'
cs = AssLauncher::Support::ConnectionString.new('File="tmp/tmp.i";Usr="root"')
tc = AssLauncher::Enterprise.thick_clients('~> 8.3').last
cmd = tc.command :designer, cs.to_args
cmd.run # Opens 1C Designer

com_conn = AssLauncher::Enterprise::Ole::IbConnection.new '~>8.3'
com_conn.__open__ cs # Open ole connection into infobase

a = com_conn.newObject 'array'
a.add 'Hello World'

puts com_con.string a.get(0) # => "Hello World"

com_con.__close__

cmd.process_holder.kill # Not forget to kill 1C Designer process!
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Testing

    $ export SIMPLECOV=YES rake test

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/leoniv/ass_launcher.

