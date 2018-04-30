# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rspec/core/rake_task'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/units/test_*.rb',
                          'test/units/**/test_*.rb']
end
desc 'Run gem tests'

RSpec::Core::RakeTask.new(:rails_spec) do |t|
  t.rspec_opts = '--require ./test/support/dummy_api/spec/rails_helper.rb'
  t.pattern = Dir.glob('test/support/dummy_api/spec/**/*_spec.rb')
end
desc 'Run rails tests'

task default: [:test, :rails_spec]
