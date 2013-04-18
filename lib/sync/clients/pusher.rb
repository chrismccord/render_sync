module Sync
  module Clients
    class Pusher

      def setup
        ::Pusher.app_id = Sync.config[:app_id]
        ::Pusher.key    = Sync.config[:api_key]
        ::Pusher.secret = Sync.config[:auth_token]
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

        def async?
          Sync.config[:async]
        end

        def publish
          if async?
            publish_asynchronous
          else
            publish_synchronous
          end
        end

        def publish_synchronous
          ::Pusher.trigger(['sync'], channel, data)
        end

        def publish_asynchronous
          ::Pusher.trigger_async(['sync'], channel, data)
        end
      end
    end
  end
end