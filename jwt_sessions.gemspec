# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "jwt_sessions/version"

Gem::Specification.new do |s|
  s.name        = "jwt_sessions"
  s.version     = JWTSessions::VERSION
  s.date        = "2024-03-05"
  s.summary     = "JWT Sessions"
  s.description = "XSS/CSRF safe JWT auth designed for SPA"
  s.authors     = ["Julija Alieckaja"]
  s.email       = "yulia.oletskaya@gmail.com"
  s.homepage    = "http://rubygems.org/gems/jwt_sessions"
  s.license     = "MIT"

  s.files         = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  s.test_files    = Dir["test/units/*", "test/units/**/*"]
  s.require_paths = ["lib"]

  s.metadata      = {
    "homepage_uri"    => "https://github.com/tuwukee/jwt_sessions",
    "changelog_uri"   => "https://github.com/tuwukee/jwt_sessions/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/tuwukee/jwt_sessions",
    "bug_tracker_uri" => "https://github.com/tuwukee/jwt_sessions/issues"
  }

  s.add_dependency "jwt", ">= 2.9", "< 3"

  s.add_development_dependency "bundler", ">= 2"
  s.add_development_dependency "rake", "~> 13.1"
  s.add_development_dependency "rspec", "~> 3.13"
end
