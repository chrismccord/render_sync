require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/pride'
require 'yaml'
require 'json'

Bundler.require(:default)

module TestHelper

  def setup
    Sync.load_config(
      File.expand_path("../../lib/generators/sync/templates/sync.yml", __FILE__),
      "test"
    )
  end
end
