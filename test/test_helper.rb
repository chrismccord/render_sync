require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/pride'
require 'yaml'
require 'json'
require 'pry'
require 'codeclimate-test-reporter'

CodeClimate::TestReporter.start

require_relative 'em_minitest_spec'

ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment.rb",  __FILE__)

Bundler.require(:default)

def setup_database
  ActiveRecord::Base.send :extend, RenderSync::Model::ClassMethods

  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS todos")
  ActiveRecord::Base.connection.execute("CREATE TABLE todos (id INTEGER PRIMARY KEY, name TEXT, complete BOOLEAN, user_id INTEGER)")

  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS users")
  ActiveRecord::Base.connection.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, cool BOOLEAN, group_id INTEGER, project_id INTEGER, age INTEGER)")

  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS groups")
  ActiveRecord::Base.connection.execute("CREATE TABLE groups (id INTEGER PRIMARY KEY, name TEXT)")

  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS projects")
  ActiveRecord::Base.connection.execute("CREATE TABLE projects (id INTEGER PRIMARY KEY, name TEXT)")
end

module TestHelper

  def setup
    RenderSync.load_config(
      File.expand_path("../fixtures/sync_faye.yml", __FILE__),
      "test"
    )
    RenderSync.logger.level = ENV['LOGLEVEL'].present? ? ENV['LOGLEVEL'].to_i : 1
  end
end

module TestHelperFaye

  def setup
    RenderSync.load_config(
      File.expand_path("../fixtures/sync_faye.yml", __FILE__),
      "test"
    )
    RenderSync.logger.level = ENV['LOGLEVEL'].present? ? ENV['LOGLEVEL'].to_i : 1
  end
end

module TestHelperPusher

  def setup
    RenderSync.load_config(
      File.expand_path("../fixtures/sync_pusher.yml", __FILE__),
      "test"
    )
    RenderSync.logger.level = ENV['LOGLEVEL'].present? ? ENV['LOGLEVEL'].to_i : 1
  end
end
