# Maintain your gem's version:
require_relative 'lib/ekylibre/banking/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name = 'ekylibre-banking'
  spec.version = Ekylibre::Banking::VERSION
  spec.authors = ['Ekylibre developers']
  spec.email = ['dev@ekylibre.com']

  spec.summary = 'Banking plugin for Ekylibre'
  spec.required_ruby_version = '>= 2.6.0'
  spec.homepage = 'https://www.ekylibre.com'
  spec.license = 'AGPL-3.0-only'

  spec.files = Dir.glob(%w[{app,config,db,lib}/**/* vendor/assets/*/*/*/*/* LICENSE.md])

  spec.add_dependency 'nordigen-ruby', '~> 1.0.0'
  spec.add_dependency 'securerandom', '~> 0.2.0'

  spec.add_development_dependency 'rubocop', '1.11.0'

  spec.require_path = ['lib']
end
