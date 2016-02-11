# Run with: rackup sync.ru -E production
require "bundler/setup"
require "yaml"
require "faye"
require "sync"

Faye::WebSocket.load_adapter 'thin'

RenderSync.load_config(
  File.expand_path("../config/sync.yml", __FILE__),
  ENV["RAILS_ENV"] || "development"
)

run RenderSync.pubsub_app
