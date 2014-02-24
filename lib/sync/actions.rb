module Sync

  module Actions

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

    # Render all sync'd partials for resource to string and publish
    # new action to pubsub server with rendered resource messages
    #
    # resource - The ActiveModel resource, or Array of ActiveModel resources
    # action - The Symbol action to publish. One of :update, :destroy
    # options - The Hash of options
    #   scope - The ActiveModel resource to scope destroy channel to
    #
    def sync_new(resource, options = {})
      sync_new resource, options
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
      partial_name = options[:partial]
      resources = [resource].flatten
      messages = resources.collect do |resource|
        if partial_name
          specified_partials(resource, sync_render_context, partial_name).collect do |partial|
            partial.message(action)
          end
        else
          all_partials(resource, sync_render_context).collect do |partial|
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
        all_partials(resource, sync_render_context).collect do |partial|
          partial.creator_for_scope(scope).message
        end
      end

      Sync.client.batch_publish(messages.flatten)
    end


    private

    # The Context class handling partial rendering
    def sync_render_context
      @sync_render_context ||= Renderer.new
    end

    # Returns Array of Partials for all given resource and context, including
    # both Partial and RefetchPartial instances
    def all_partials(resource, context)
      Partial.all(resource, context) + RefetchPartial.all(resource, context)
    end

    # Returns an Array containing both the Partial and RefetchPartial instances
    # for a given resource, context and partial name
    def specified_partials(resource, context, partial_name)
      [Partial.find(resource, partial_name, context), RefetchPartial.find(resource, partial_name, context)].compact
    end
  end
end
