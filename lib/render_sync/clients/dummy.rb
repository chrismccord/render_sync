module RenderSync
  module Clients
    class Dummy
      def method_missing(*args, &block)
        nil
      end

      class Message
        def self.method_missing(*args, &block)
          nil
        end

        def initialize(*)
        end

        def method_missing(*args, &block)
          nil
        end
      end
    end
  end
end
