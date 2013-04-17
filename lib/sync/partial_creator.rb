module Sync
  class PartialCreator
    attr_accessor :name, :resource, :context, :partial

    def initialize(name, resource, context)
      self.name = name
      self.resource = resource
      self.context = context
      self.partial = Partial.new(name, resource, nil, context)
    end

    def channel
      "/" + Channel.new("#{polymorphic_path}-_#{name}").signature
    end

    def selector
      "#{channel}"
    end

    def sync_new
      message.publish
    end

    def message
      Message.new(channel,
        html: partial.render_to_string,
        channelUpdate: partial.channel_for_action(:update),
        channelDestroy: partial.channel_for_action(:destroy),
        selectorStart: partial.selector_start,
        selectorEnd: partial.selector_end
      )
    end


    private

    def resource_name
      resource.class.model_name.to_s.downcase
    end

    def plural_resource_name
      resource_name.pluralize
    end

    def polymorphic_path
      "/#{plural_resource_name}/new"
    end
  end
end
