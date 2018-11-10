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

['redis', 'memory'].each do |adapter|
  RSpec::Core::RakeTask.new("rails_spec_with_#{adapter}_adapter") do |t|
    ENV['STORE_ADAPTER'] = adapter
    t.rspec_opts = '--require ./test/support/dummy_api/spec/rails_helper.rb'
    t.pattern = Dir.glob('test/support/dummy_api/spec/**/*_spec.rb')
  end
  desc 'Run rails tests (with #{adapter} adapter)'

  RSpec::Core::RakeTask.new("sinatra_spec_with_#{adapter}_adapter") do |t|
    ENV['STORE_ADAPTER'] = adapter
    t.rspec_opts = '--require ./test/support/dummy_sinatra_api/spec/spec_helper.rb'
    t.pattern = Dir.glob('test/support/dummy_sinatra_api/spec/*_spec.rb')
  end
  desc "Run sinatra tests (with #{adapter} adapter)"
end

task default: [
  :test,
  :sinatra_spec_with_redis_adapter,
  :sinatra_spec_with_memory_adapter,
  :rails_spec_with_redis_adapter,
  :rails_spec_with_memory_adapter
]
