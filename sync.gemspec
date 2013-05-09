Gem::Specification.new do |s|
  s.name        = "sync"
  s.version     = "0.1.10"
  s.author      = "Chris McCord"
  s.email       = "chris@chrismccord.com"
  s.homepage    = "http://github.com/chrismccord/sync"
  s.summary     = "Realtime Rails Partials"
  s.description = "Sync turns your Rails partials realtime with automatic updates through Faye"
  s.files       = Dir["{app,lib,test}/**/*", "[A-Z]*", "init.rb"] - ["Gemfile.lock"]
  s.require_path = "lib"

  s.add_dependency 'em-http-request'

  s.add_development_dependency 'faye'
  s.add_development_dependency 'thin'
  s.add_development_dependency 'pusher', '~> 0.11.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rails', '~> 3.2.13'
  s.add_development_dependency 'mocha', '~> 0.13.3'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pry'

  s.required_rubygems_version = ">= 1.3.4"
end
