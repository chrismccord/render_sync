require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/pride'
require 'yaml'
require 'json'
require 'pry'

require_relative 'em_minitest_spec'

Bundler.require(:default)

def setup_database
  ActiveRecord::Base.send :extend, Sync::Model::ClassMethods
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: "test/fixtures/test.sqlite3",
    pool: 5,
    timeout: 5000
  )
  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS todos")
  ActiveRecord::Base.connection.execute("CREATE TABLE todos (id INTEGER PRIMARY KEY, name TEXT, complete BOOLEAN, user_id INTEGER)")

  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS users")
  ActiveRecord::Base.connection.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, cool BOOLEAN, group_id INTEGER, age INTEGER)")

  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS groups")
  ActiveRecord::Base.connection.execute("CREATE TABLE groups (id INTEGER PRIMARY KEY, name TEXT)")
end

module TestHelper

  def setup
    Sync.load_config(
      File.expand_path("../fixtures/sync_faye.yml", __FILE__),
      "test"
    )
  end
end

module TestHelperFaye

  def setup
    Sync.load_config(
      File.expand_path("../fixtures/sync_faye.yml", __FILE__),
      "test"
    )
  end
end

module TestHelperPusher

  def setup
    Sync.load_config(
      File.expand_path("../fixtures/sync_pusher.yml", __FILE__),
      "test"
    )
  end
end


