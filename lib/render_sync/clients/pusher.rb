module RenderSync
  module Clients
    class Pusher

      def setup
        require 'pusher'
        ::Pusher.app_id = RenderSync.app_id
        ::Pusher.key    = RenderSync.api_key
        ::Pusher.secret = RenderSync.auth_token

        if RenderSync.pusher_api_scheme
          ::Pusher.scheme = RenderSync.pusher_api_scheme
        end

        if RenderSync.pusher_api_host
          ::Pusher.host = RenderSync.pusher_api_host
        end

        if RenderSync.pusher_api_port
          ::Pusher.port = RenderSync.pusher_api_port
        end
      end

      def batch_publish(*args)
        Message.batch_publish(*args)
      end

      def build_message(*args)
        Message.new(*args)
      end

      # Public: Normalize channel to adapter supported format
      #
      # channel - The string channel name
      #
      # Returns The normalized channel prefixed with supported format for Pusher
      def normalize_channel(channel)
        channel
      end


      class Message

        attr_accessor :channel, :data

        def self.batch_publish(messages)
          messages.each do |message|
            message.publish
          end
        end

        def initialize(channel, data)
          self.channel = channel
          self.data = data
        end

        def publish
          if RenderSync.async?
            publish_asynchronous
          else
            publish_synchronous
          end
        end

        def publish_synchronous
          ::Pusher.trigger([channel], 'sync', data)
        end

        def publish_asynchronous
          RenderSync.reactor.perform do
            ::Pusher.trigger_async([channel], 'sync', data)
          end
        end
      end
    end
  end
end
