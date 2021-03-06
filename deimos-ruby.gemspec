# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deimos/version'

Gem::Specification.new do |spec|
  spec.name          = 'deimos-ruby'
  spec.version       = Deimos::VERSION
  spec.authors       = ['Daniel Orner']
  spec.email         = ['daniel.orner@wishabi.com']
  spec.summary       = 'Kafka libraries for Ruby.'
  spec.homepage      = ''
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency('avro-patches', '~> 0.3')
  spec.add_runtime_dependency('avro_turf', '~> 0.8')
  spec.add_runtime_dependency('phobos', '~> 1.8.2.pre.beta2')
  spec.add_runtime_dependency('ruby-kafka', '~> 0.7')

  spec.add_development_dependency('activerecord', '~> 5.2')
  spec.add_development_dependency('activerecord-import')
  spec.add_development_dependency('bundler', '~> 1')
  spec.add_development_dependency('ddtrace', '~> 0.11')
  spec.add_development_dependency('dogstatsd-ruby', '~> 4.2')
  spec.add_development_dependency('guard', '~> 2')
  spec.add_development_dependency('guard-rspec', '~> 4')
  spec.add_development_dependency('guard-rubocop', '~> 1')
  spec.add_development_dependency('mysql2', '~> 0.5')
  spec.add_development_dependency('pg', '~> 1.1')
  spec.add_development_dependency('rails', '~> 5.2')
  spec.add_development_dependency('rake', '~> 10')
  spec.add_development_dependency('rspec', '~> 3')
  spec.add_development_dependency('rspec_junit_formatter', '~>0.3')
  spec.add_development_dependency('rubocop', '~> 0.72')
  spec.add_development_dependency('rubocop-rspec', '~> 1.27')
  spec.add_development_dependency('sqlite3', '~> 1.3')
end
