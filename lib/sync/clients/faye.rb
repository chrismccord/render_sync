module Sync
  module Clients
    class Faye

      def setup
        # nothing to set up
      end

      def batch_publish(*args)
        Message.batch_publish(*args)
      end

      def build_message(*args)
        Message.new(*args)
      end

      class Message

        attr_accessor :channel, :data

        def self.batch_publish(messages, net_http = Net::HTTP)
          net_http.post_form(
            URI.parse(Sync.config[:server]), 
            message: {
              channel: "/batch_publish",
              data: messages.collect(&:to_hash),
              ext: { auth_token: Sync.config[:auth_token] }
            }.to_json
          )
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
              auth_token: Sync.config[:auth_token]
            }
          }
        end

        def to_json
          to_hash.to_json
        end

        def publish(net_http = Net::HTTP)
          net_http.post_form URI.parse(Sync.config[:server]), message: self.to_json
        end
      end
    end
  end
end