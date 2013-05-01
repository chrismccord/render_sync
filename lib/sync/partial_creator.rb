module Sync
  class PartialCreator
    attr_accessor :name, :resource, :scoped_resource, :context, :partial

    def initialize(name, resource, scoped_resource, context)
      self.name = name
      self.resource = Resource.new(resource)
      self.scoped_resource = Resource.new(scoped_resource) if scoped_resource
      self.context = context
      self.partial = Partial.new(name, self.resource.model, nil, context)
    end

    def channel
      @channel ||= Channel.new("#{polymorphic_path}-_#{name}").to_s
    end

    def selector
      "#{channel}"
    end

    def sync_new
      message.publish
    end

    def message
      Sync.client.build_message(channel,
        html: partial.render_to_string,
        channelUpdate: partial.channel_for_action(:update),
        channelDestroy: partial.channel_for_action(:destroy),
        selectorStart: partial.selector_start,
        selectorEnd: partial.selector_end
      )
    end


    private

    def polymorphic_path
      if scoped_resource
        "#{scoped_resource.polymorphic_path}#{resource.polymorphic_new_path}"
      else
        "#{resource.polymorphic_new_path}"
      end
    end
  end
end
