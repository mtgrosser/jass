lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jass/version'

Gem::Specification.new do |s|
  s.name          = 'jass'
  s.version       = Jass::VERSION
  s.date          = '2018-03-22'
  s.authors       = ['Matthias Grosser']
  s.email         = ['mtgrosser@gmx.net']
  s.license       = 'MIT'

  s.summary       = 'ES6 goodness for Rails'
  s.description   = 'ES6 support for the Rails asset pipeline'
  s.homepage      = 'https://github.com/mtgrosser/jass'

  s.files = ['LICENSE', 'README.md', 'vendor/package.json', 'vendor/yarn.lock'] + Dir['lib/**/*.rb'] + Dir['vendor/node_modules/**/*']
  
  s.required_ruby_version = '>= 2.3.0'
  
  s.add_dependency 'schmooze'
  s.add_dependency 'railties', '~> 5.1.5'
  s.add_dependency 'sprockets', '>= 3.0.0'
  
  s.add_development_dependency 'bundler', '~> 1.16'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'minitest', '~> 5.0'
end
