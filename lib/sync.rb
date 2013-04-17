require "digest/sha1"
require "net/http"
require "net/https"
require 'sync/controller_helpers'
require 'sync/view_helpers'
require 'sync/faye_extension'
require 'sync/partial_creator'
require 'sync/partial'
require 'sync/channel'
require 'sync/message'
require 'sync/engine' if defined? Rails
require 'faye'

module Sync

  class << self
    attr_reader :config

    # Resets the configuration to the default (empty hash)
    def reset_config
      @config = {}
    end

    # Loads the  configuration from a given YAML file and environment (such as production)
    def load_config(filename, environment)
      reset_config
      yaml = YAML.load_file(filename)[environment.to_s]
      raise ArgumentError, "The #{environment} environment does not exist in #{filename}" if yaml.nil?
      yaml.each{|key, value| config[key.to_sym] = value }
    end

    # Returns the Faye Rack application.
    # Any options given are passed to the Faye::RackAdapter.
    def pubsub_app(options = {})
      Faye::RackAdapter.new({
        mount: config[:mount] || "/faye",
        timeout: config[:timeout] || 45,
        extensions: [FayeExtension.new]
      }.merge(options))
    end

    def pubsub_js_url
      "#{Sync.config[:server]}/faye.js"
    end
  end
end

