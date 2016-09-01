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

  spec.add_dependency "inifile"
  spec.add_dependency "methadone"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "clamp"
end
