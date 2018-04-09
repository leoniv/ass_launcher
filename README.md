[![Code Climate](https://codeclimate.com/github/leoniv/ass_launcher/badges/gpa.svg)](https://codeclimate.com/github/leoniv/ass_launcher)
[![Gem Version](https://badge.fury.io/rb/ass_launcher.svg)](https://badge.fury.io/rb/ass_launcher)

# AssLauncher

Ruby wrapper for 1C:Enterprise platform.

Goal of this to make easily and friendly writing scripts for development
and support lifecycle of 1C:Enterprise applications

`AssLauncher` is cross platform but **it full tested in `Cygwin` only!**. In  `Windows` and `Linux` it works too.

In `Linux` don't support `OLE` feature. Don't known why I told it ;)


## Quick start

### Using `AssLauncher` as a library

Add this line to your application's Gemfile:

```ruby
gem 'ass_launcher'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ass_launcher

For example, writing script which dumping 1C:Enterprise application

```ruby
require 'ass_launcher'

include AssLauncher::Api

def main(dupm_path)
  # Get wrapper for the thck client
  thick_client = thicks('~> 8.3.8.0').last

  # Fail if 1C:Enterprise installation not found
  fail '1C:Enterprise not found' if thick_client.nil?

  # Build designer command
  designer = thick_client.command :designer do
    _S 'enterprse_server/application_name'
    dumpIB dupm_path
  end

  # Execute command
  designer.run.wait

  # Verify result
  designer.process_holder.result.verify!
end

main ARGV[0]
```

### Command line utility `ass-launcher`

From version `0.3.0` `AssLauncher` provides console tool `ass-launcher` wich has
features:

- make new 1C:Enterprise application instance (aka information base)
- run 1C:Enterprise
- show help about 1C:Enterprise CLI parameters
- and some more

For more info about `ass-launcher` execute:

    $ass-launcher --help


## x86_64 1C:Enterprise for Windows

From `v8.3.9` 1C provides x86_64 arch platform for Windows.

For choosing which arch of 1C binary you need
`AssLauncher::Enterprise::BinaryWrapper` has `arch` property and some helpers
in `AssLauncher::Api` like a `*_i386` and `*_x86_64`.

For 1C inproc OLE server aka `comcntr.dll`, arch of 1C binary selects
automaticaly in depends of Ruby arch.

But using of `x86_64` inproc OLE server is unstable and Ruby usually crashed:

```
....*** buffer overflow detected ***: terminated
rake aborted!
SignalException: SIGABRT
```

On default using of `x86_64` 1C OLE server is forbidden. For forcing to use
`x86_64` OLE server set config flag `use_x86_64_ole`:

```ruby
  AssLauncher.configure do |conf|
    conf.use_x86_64_ole = true
  end
```

## Usage

### Examples

For more usage examples see [examples](examples/)

For beginning look at
[examples/enterprise_running_example.rb](examples/enterprise_running_example.rb)

All [examples](examples/) executable. For run them require
1C:Enterprise platform version defined in `Examples::MIN_PLATFORM_VERSION`

Run all examples:

    $rake run_examples

Or run specified example:

    $rake run_examples TEST=examples/enterprise_running_example.rb

### Troubles

Directory [examples/troubles](examples/troubles) contains examples
which describe troubles with executing 1C:Enterprise binary.

All [examples/troubles](examples/troubles) are executable too.

Run all troubles:

    $rake run_trouble_examples

**Be careful to run [examples/troubles](examples/troubles)! Learn sources before run it.**

## Help

If you have any questions open issue with `question` lable

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Development helper

`AssLauncher` include [bin/dev-helper](bin/dev-helper) utility for contributors.

    $bin/dev-helper --help

### Testing

#### Run unit tests:

    $export SIMPLECOV=YES && rake test

Unit tests is isolated and doesn't require installation of 1C:Enterprise

#### Run examples:

Examples writed as `Minitest::Spec`. About run examples see above

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/leoniv/ass_launcher.
