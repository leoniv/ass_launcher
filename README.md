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

disainer = AssLauncher::Disainer.new('8.3.5')

disainer.start(connection_string)

disainer.dump_config(connection_string, arguments)

disainer.dump_db_config(connection_string, arguments)

thin_client = AssLauncher::ThinClient.new('8.3.6')

thin_client.start(connection_string, arguments)

# etc ... TODO describe actual interface
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/leoniv/ass_launcher.

