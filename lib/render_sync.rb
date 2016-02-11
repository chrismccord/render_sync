require 'eventmachine'
require 'monitor'
require 'digest/sha1'
require 'erb'
require 'net/http'
require 'net/https'
require 'logger'
require 'render_sync/renderer'
require 'render_sync/actions'
require 'render_sync/action'
require 'render_sync/controller_helpers'
require 'render_sync/view_helpers'
require 'render_sync/model_change_tracking'
require 'render_sync/model_actions'
require 'render_sync/model_syncing'
require 'render_sync/model_touching'
require 'render_sync/model'
require 'render_sync/scope'
require 'render_sync/scope_definition'
require 'render_sync/refetch_model'
require 'render_sync/faye_extension'
require 'render_sync/partial_creator'
require 'render_sync/refetch_partial_creator'
require 'render_sync/partial'
require 'render_sync/refetch_partial'
require 'render_sync/channel'
require 'render_sync/resource'
require 'render_sync/clients/faye'
require 'render_sync/clients/pusher'
require 'render_sync/clients/dummy'
require 'render_sync/reactor'
if defined? Rails
  require 'render_sync/erb_tracker'
  require 'render_sync/engine'
end

module RenderSync

  class << self
    attr_accessor :config, :client, :logger

    def config
      @config || {}
    end

    def config_json
      @config_json ||= begin
        {
          server: server,
          api_key: api_key,
          pusher_ws_host: pusher_ws_host,
          pusher_ws_port: pusher_ws_port,
          pusher_wss_port: pusher_wss_port,
          pusher_encrypted: pusher_encrypted,
          adapter: adapter
        }.reject { |k, v| v.nil? }.to_json
      end
    end

    # Resets the configuration to the default (empty hash)
    def reset_config
      @config = {}
      @config_json = nil
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
      @client = RenderSync::Clients.const_get(adapter).new
      @client.setup
    end

    def setup_dummy_client
      config[:auth_token] = 'dummy_auth_token'
      @client = RenderSync::Clients::Dummy.new
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

    def pusher_api_scheme
      config[:pusher_api_scheme]
    end

    def pusher_api_host
      config[:pusher_api_host]
    end

    def pusher_api_port
      config[:pusher_api_port]
    end

    def pusher_ws_host
      config[:pusher_ws_host]
    end

    def pusher_ws_port
      config[:pusher_ws_port]
    end

    def pusher_wss_port
      config[:pusher_wss_port]
    end

    def pusher_encrypted
      if config[:pusher_encrypted].nil?
        true
      else
        config[:pusher_encrypted]
      end
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
