# -*- encoding: utf-8 -*-
require File.expand_path("../lib/heroku_tasks/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "heroku_tasks"
  s.version     = HerokuTasks::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Thibaud Guillaume-Gentil"]
  s.email       = ["thibaud@thibaud.me"]
  s.homepage    = "http://rubygems.org/gems/heroku_tasks"
  s.summary     = "Bundle of rake tasks to manage staging/production heroku deploy"
  s.description = "Bundle of rake tasks to manage staging/production heroku deploy."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "heroku_tasks"

  s.add_development_dependency "bundler", ">= 1.0.0.rc.6"

  s.files        = Dir.glob("{lib}/**/*") + %w[README.rdoc]
  s.require_path = 'lib'
end
