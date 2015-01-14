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
  s.add_runtime_dependency 'executrix', '~> 1.4.0'
  s.add_runtime_dependency 'pg', '~> 0.18.1'
  # using aws-sdk v1 since v2 is still not stable
  s.add_runtime_dependency 'aws-sdk', '< 2.0'
  # can not use slop 4.0 due to pry depending on 3.x
  # https://github.com/pry/pry/issues/1338
  s.add_runtime_dependency 'slop', '~> 3.6'
  s.add_runtime_dependency 'parallel', '~> 1.3.3'

  s.add_development_dependency 'rake', '~> 10.4.2'
  s.add_development_dependency 'pry', '~> 0.10.1'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
