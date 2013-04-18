require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/pride'
require 'yaml'
require 'json'
require_relative 'em_minitest_spec'

Bundler.require(:default)

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


