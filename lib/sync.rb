require 'eventmachine'
require 'monitor'
require 'digest/sha1'
require 'erb'
require 'net/http'
require 'net/https'
require 'logger'
require 'sync/renderer'
require 'sync/actions'
require 'sync/action'
require 'sync/controller_helpers'
require 'sync/view_helpers'
require 'sync/model_change_tracking'
require 'sync/model_actions'
require 'sync/model_syncing'
require 'sync/model_touching'
require 'sync/model'
require 'sync/scope'
require 'sync/scope_definition'
require 'sync/refetch_model'
require 'sync/faye_extension'
require 'sync/partial_creator'
require 'sync/refetch_partial_creator'
require 'sync/partial'
require 'sync/refetch_partial'
require 'sync/channel'
require 'sync/resource'
require 'sync/clients/faye'
require 'sync/clients/pusher'
require 'sync/clients/dummy'
require 'sync/reactor'
if defined? Rails
  require 'sync/erb_tracker'
  require 'sync/engine'
end

module Sync

  class << self
    attr_accessor :config, :client, :logger

    def config
      @config || {}
    end

    # Resets the configuration to the default (empty hash)
    def reset_config
      @config = {}
    end

    # Loads the configuration from a given YAML file and environment (such as production)
    def load_config(filename, environment)
      reset_config
      yaml = YAML.load(ERB.new(File.read(filename)).result)[environment.to_s]
      raise ArgumentError, "The #{environment} environment does not exist in #{filename}" if yaml.nil?
      yaml.each{|key, value| config[key.to_sym] = value }
      setup_logger

      if adapter
        setup_client
      else
        setup_dummy_client
      end
    end

    def setup_client
      raise ArgumentError, "auth_token missing" if config[:auth_token].nil?
      @client = Sync::Clients.const_get(adapter).new
      @client.setup
    end

    def setup_dummy_client
      config[:auth_token] = 'dummy_auth_token'
      @client = Sync::Clients::Dummy.new
    end

    def setup_logger
      @logger = (defined?(Rails) && Rails.logger) ? Rails.logger : Logger.new(STDOUT)
    end

    def async?
      config[:async]
    end

    def server
      config[:server]
    end

    def adapter_javascript_url
      config[:adapter_javascript_url]
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

    def reactor
      @reactor ||= Reactor.new
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

    def views_root
      Rails.root.join('app', 'views', 'sync')
    end
  end
end

