module RenderSync
  module Clients
    class Faye

      def setup
        require 'faye'
        # nothing to set up
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
      # Returns The normalized channel prefixed with supported format for Faye
      def normalize_channel(channel)
        "/#{channel}"
      end


      class Message

        attr_accessor :channel, :data

        def self.batch_publish(messages)
          if RenderSync.async?
            batch_publish_asynchronous(messages)
          else
            batch_publish_synchronous(messages)
          end
        end

        def self.batch_publish_synchronous(messages)
          Net::HTTP.post_form(
            URI.parse(RenderSync.server), 
            message: batch_messages_query_hash(messages).to_json
          )
        end

        def self.batch_publish_asynchronous(messages)
          RenderSync.reactor.perform do
            EM::HttpRequest.new(RenderSync.server).post(body: {
              message: batch_messages_query_hash(messages).to_json
            })
          end
        end

        def self.batch_messages_query_hash(messages)
          {
            channel: "/batch_publish",
            data: messages.collect(&:to_hash),
            ext: { auth_token: RenderSync.auth_token }
          }
        end

        def initialize(channel, data)
          self.channel = channel
          self.data = data
        end

        def to_hash
          {
            channel: channel,
            data: data,
            ext: {
              auth_token: RenderSync.auth_token
            }
          }
        end

        def to_json
          to_hash.to_json
        end

        def publish
          if RenderSync.async?
            publish_asynchronous
          else
            publish_synchronous
          end
        end

        def publish_synchronous
          Net::HTTP.post_form URI.parse(RenderSync.server), message: to_json
        end

        def publish_asynchronous
          RenderSync.reactor.perform do
            EM::HttpRequest.new(RenderSync.server).post(body: {
              message: self.to_json
            })
          end
        end
      end
    end
  end
end
