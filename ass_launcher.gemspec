# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ass_launcher/version'

Gem::Specification.new do |spec|
  spec.name          = "ass_launcher"
  spec.version       = AssLauncher::VERSION
  spec.authors       = ["Leonid Vlasov"]
  spec.email         = ["leoniv.vlasov@gmail.com"]

  spec.summary       = %q{Ruby wrapper for 1C:Enterprise platform}
  spec.description   = %q{Don't ask why this necessary. Believe this necessary!}
  spec.homepage      = "https://github.com/leoniv/ass_launcher"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.license       = 'MIT'

  spec.required_ruby_version = '~> 2.0'

  spec.add_dependency "inifile", "~> 3.0"
  spec.add_dependency "methadone", "~> 1.9"
  spec.add_dependency "addressable", "= 2.4.0"
  spec.add_dependency "clamp", "~> 1.2"
  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "io-console", "~> 0.4.6"
  spec.add_dependency "command_line_reporter", '~> 3.0'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.11"
  spec.add_development_dependency "pry", "~> 0.11"
  spec.add_development_dependency "mocha", "= 1.1.0"
  spec.add_development_dependency "simplecov", "~> 0.15"
  spec.add_development_dependency "coderay", "~> 1.1"
  spec.add_development_dependency "yard"
end
