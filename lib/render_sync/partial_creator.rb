module RenderSync
  class PartialCreator
    attr_accessor :name, :resource, :context, :partial

    def initialize(name, resource, scopes, context)
      self.name = name
      self.resource = Resource.new(resource, scopes)
      self.context = context
      self.partial = Partial.new(name, self.resource.model, scopes, context)
    end

    def auth_token
      @auth_token ||= Channel.new("#{polymorphic_path}-_#{name}").to_s
    end

    def channel
      @channel ||= auth_token
    end

    def selector
      "#{channel}"
    end

    def sync_new
      message.publish
    end

    def message
      RenderSync.client.build_message(channel,
        html: partial.render_to_string,
        resourceId: resource.id,
        authToken: partial.auth_token,
        channelUpdate: partial.channel_for_action(:update),
        channelDestroy: partial.channel_for_action(:destroy),
        selectorStart: partial.selector_start,
        selectorEnd: partial.selector_end
      )
    end


    private

    def polymorphic_path
      resource.polymorphic_new_path
    end
  end
end
