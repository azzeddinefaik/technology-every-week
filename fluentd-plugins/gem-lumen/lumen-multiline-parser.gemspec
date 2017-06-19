# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "parser_lumen_multiline"
  gem.description = "Lumen log parser plugin for Fluentd"
  gem.homepage    = "git@github.com:azzeddinefaik/technology-every-week.git"
  gem.version     = File.read("VERSION").strip
  gem.authors     = ["Azzeddine Faik"]
  gem.email       = "faikazzeddine19@gmail.com"
  gem.has_rdoc    = false
  gem.summary     = "Plugin for lumen logs"
  gem.license     = 'Apache License (2.0)'
  gem.files       = `git ls-files`.split("\n")
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency "fluentd", "~> 0.12"
  gem.add_development_dependency "rake", ">= 0.9.2"
end