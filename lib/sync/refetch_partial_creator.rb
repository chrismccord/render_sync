module Sync
  class RefetchPartialCreator < PartialCreator

    def initialize(name, resource, scoped_resource, context)
      self.name = name
      self.resource = Resource.new(resource)
      self.scoped_resource = Resource.new(scoped_resource) if scoped_resource
      self.context = context
      self.partial = RefetchPartial.new(name, self.resource.model, nil, context)
    end

    def message
      Sync.client.build_message(channel,
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
