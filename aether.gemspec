# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'aether/version'

Gem::Specification.new do |s|
  s.name = 'aether'
  s.version = Aether::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Thomas Dziedzic']
  s.email = ['thomas@pagerduty.com']
  s.homepage = 'https://github.com/PagerDuty/pd-bizops-aether'
  s.summary = 'salesforce data replication to redshift'
  s.description = 'salesforce data replication to redshift'

  s.add_runtime_dependency 'restforce', '~> 1.5.1'

  s.add_development_dependency 'rake', '~> 10.4.2'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
