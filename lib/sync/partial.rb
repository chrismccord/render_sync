module Sync
  class Partial
    attr_accessor :name, :resource, :channel, :context

    def self.all(resource, context)
      partials = []
      plural_resource_name = resource.class.model_name.to_s.downcase.pluralize
      Dir.foreach(Rails.root.join("app/views/sync/#{plural_resource_name}/")) do |partial|
        next if partial == '.' or partial == '..'
        partial_name = partial.split(".").first
        partial_name.slice!(0)
        partials << Partial.new(partial_name, resource, nil, context)
      end

      partials
    end


    def initialize(name, resource, channel, context)
      self.name = name
      self.resource = resource
      self.channel = channel
      self.context = context
    end

    def render_to_string
      context.render_to_string(partial: path, locals: locals)
    end
    
    def render
      context.render(partial: path, locals: locals)
    end

    def sync(action)
      message(action).publish
    end

    def message(action)
      Sync.client.build_message channel_for_action(action), html: render_to_string
    end

    def channel_id
      Channel.new("#{polymorphic_path}-_#{name}").signature
    end

    def channel_for_action(action)
      "/#{channel_id}-#{action}"
    end

    def selector_start
      "#{channel_id}-start"
    end

    def selector_end
      "#{channel_id}-end"
    end


    private

    def path
      "sync/#{plural_resource_name}/#{name}"
    end

    def resource_name
      resource.class.model_name.to_s.downcase
    end

    def plural_resource_name
      resource_name.pluralize
    end

    def locals
      locals_hash = {}
      locals_hash[resource_name.to_sym] = resource

      locals_hash
    end

    def polymorphic_path
      if channel
        "/#{plural_resource_name}/#{channel}"
      else
        "/#{plural_resource_name}/#{resource.id}"
      end
    end
  end
end
