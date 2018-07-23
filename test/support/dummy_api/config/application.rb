require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

$LOAD_PATH.push File.expand_path('../../../../../lib', __FILE__)
require 'jwt'
require 'jwt_sessions'

module DummyApi
  class Application < Rails::Application
    if Rails::VERSION::MAJOR >= 5
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end
  end
end
