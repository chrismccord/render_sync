module Sync

  module ControllerHelpers

    private

    def sync_update(resource, options = {})
      sync resource, :update, options
    end

    def sync_destroy(resource, options = {})
      sync resource, :destroy, options
    end

    def sync(resource, action, options = {})
      channel = options[:channel]
      resources = [resource].flatten
      messages = resources.collect do |resource|
        if channel
          Sync::Partial.new(channel, resource, channel, self).message(action)
        else
          Sync::Partial.all(resource, self).collect do |partial|
            partial.message(action)
          end
        end
      end

      Sync.client.batch_publish(messages.flatten)
    end

    def sync_new(resource, options = {})
      scope = options[:scope]
      resources = [resource].flatten
      messages = resources.collect do |resource|
        Sync::Partial.all(resource, self).collect do |partial|
          Sync::PartialCreator.new(partial.name, resource, scope, self).message
        end
      end

      Sync.client.batch_publish(messages.flatten)
    end
  end
end
