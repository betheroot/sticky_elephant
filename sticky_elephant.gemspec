# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sticky_elephant/version'

Gem::Specification.new do |spec|
  spec.name          = "sticky_elephant"
  spec.version       = StickyElephant::VERSION
  spec.authors       = ["Forrest Fleming"]
  spec.email         = ["ffleming@gmail.com"]

  spec.summary       = %q{Medium interaction PostgreSQL honeypot}
  spec.description   = %q{Log logins and queries for an emulated PostgresQL server}
  spec.homepage      = "https://github.com/ffleming/sticky_elephant"
  spec.licenses      = %w(MIT)

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "hpfeeds", "~> 0.1", ">= 0.1.6"
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug", "~> 3.4"
end
