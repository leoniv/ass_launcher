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

maker = AssLauncher::IbMaker.new('8.2')
maker.run(connection_string, arguments)

designer = AssLauncher::Designer.new('8.3.5')
designer.run(connection_string, arguments)

designer.batch(connection_string, arguments).run(butch_command)

thin_client = AssLauncher::ThinClient.new('8.3.6')
thin_client.run(connection_string, arguments)

thick_client = AssLauncher::ThickClient.new('8.3.6')
thick_client.run(connection_string, arguments)

web_client = AssLauncher::WebClient.new()
web_client.run(connection_string, arguments)

# etc ... TODO describe actual interface
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/leoniv/ass_launcher.

