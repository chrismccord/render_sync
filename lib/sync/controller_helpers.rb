module Sync

  module ControllerHelpers

    private

    # Render all resource sync'd partial to string and publish update
    # to pubsub server with rendered resource messages
    #
    # resource - The ActiveModel resource, or Array of ActiveModel resources
    # options - The Hash of options
    #   scope - The ActiveModel resource to scope update channel to
    #
    def sync_update(resource, options = {})
      sync resource, :update, options
    end

    # Publish destroy event to pubsub server for given resource
    #
    # resource - The ActiveModel resource, or Array of ActiveModel resources
    # options - The Hash of options
    #   scope - The ActiveModel resource to scope destroy channel to
    #   
    def sync_destroy(resource, options = {})
      sync resource, :destroy, options
    end

    # Render all resource sync'd partial to string and publish action
    # to pubsub server with rendered resource messages
    #
    # resource - The ActiveModel resource
    # action - The Symbol action to publish. One of :update, :destroy
    # options - The Hash of options
    #   scope - The ActiveModel resource to scope destroy channel to
    #   
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

    # Render all sync'd partials for resource to string and publish 
    # new action to pubsub server with rendered resource messages
    #
    # resource - The ActiveModel resource, or Array of ActiveModel resources
    # action - The Symbol action to publish. One of :update, :destroy
    # options - The Hash of options
    #   scope - The ActiveModel resource to scope destroy channel to
    #   
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
