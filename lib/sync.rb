require "digest/sha1"
require "net/http"
require "net/https"
require 'sync/controller_helpers'
require 'sync/view_helpers'
require 'sync/faye_extension'
require 'sync/partial_creator'
require 'sync/partial'
require 'sync/channel'
require 'sync/resource'
require 'sync/clients/faye'
require 'sync/clients/pusher'
require 'sync/engine' if defined? Rails
require 'faye'

module Sync

  class << self
    attr_reader :config, :client

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
      setup_client
    end

    def setup_client
      @client = Sync::Clients.const_get(adapter).new
      @client.setup
    end

    def async?
      config[:async]
    end

    def server
      config[:server]
    end

    def adapater_javascript_url
      config[:adapater_javascript_url]
    end

    def auth_token
      config[:auth_token]
    end

    def adapter
      config[:adapter]
    end

    def app_id
      config[:app_id]
    end

    def api_key
      config[:api_key]
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
  end
end

