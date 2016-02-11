module RenderSync
  class RefetchPartialCreator < PartialCreator

    def initialize(name, resource, scoped_resource, context)
      super
      self.partial = RefetchPartial.new(name, self.resource.model, nil, context)
    end

    def message
      RenderSync.client.build_message(channel,
        refetch: true,
        resourceId: resource.id,
        authToken: partial.auth_token,
        channelUpdate: partial.channel_for_action(:update),
        channelDestroy: partial.channel_for_action(:destroy),
        selectorStart: partial.selector_start,
        selectorEnd: partial.selector_end
      )
    end
  end
end
