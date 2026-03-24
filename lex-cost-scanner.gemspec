# frozen_string_literal: true

require_relative 'lib/legion/extensions/cost_scanner/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cost-scanner'
  spec.version       = Legion::Extensions::CostScanner::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@legionio.dev']
  spec.summary       = 'Cloud cost optimization scanner for LegionIO'
  spec.description   = 'Scans AWS/Azure accounts for idle resources, classifies findings via LLM, delivers weekly Slack reports'
  spec.homepage      = 'https://github.com/LegionIO/lex-cost-scanner'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'legion-cache',     '>= 1.3.11'
  spec.add_dependency 'legion-crypt',     '>= 1.4.9'
  spec.add_dependency 'legion-data',      '>= 1.4.17'
  spec.add_dependency 'legion-json',      '>= 1.2.1'
  spec.add_dependency 'legion-logging',   '>= 1.3.2'
  spec.add_dependency 'legion-settings',  '>= 1.3.14'
  spec.add_dependency 'legion-transport', '>= 1.3.9'
end
