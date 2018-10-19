# frozen_string_literal: true
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'jwt_sessions/version'

Gem::Specification.new do |s|
  s.name        = 'jwt_sessions'
  s.version     = JWTSessions::VERSION
  s.date        = '2018-10-09'
  s.summary     = 'JWT Sessions'
  s.description = 'XSS/CSRF safe JWT auth designed for SPA'
  s.authors     = ['Yulia Oletskaya']
  s.email       = 'yulia.oletskaya@gmail.com'
  s.homepage    = 'http://rubygems.org/gems/jwt_sessions'
  s.license     = 'MIT'

  s.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  s.test_files    = Dir['test/units/*', 'test/units/**/*']
  s.require_paths = ['lib']

  s.add_dependency 'jwt', '>= 2.1', '< 3'
  s.add_dependency 'redis', '>= 3', '< 5'
  s.add_dependency 'moneta', '>= 1'

  s.add_development_dependency 'bundler', '~> 1.16'
  s.add_development_dependency 'minitest', '~> 5.11'
  s.add_development_dependency 'pry', '~> 0.11'
  s.add_development_dependency 'rake', '~> 12.3'
end
