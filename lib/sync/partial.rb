module Sync

  class Partial
    attr_accessor :name, :resource, :channel, :context

    def self.all(model, context)
      resource = Resource.new(model)
      partials = []
      Dir.foreach(Rails.root.join("app/views/sync/#{resource.plural_name}/")) do |filename|
        partial_file = PartialFile.new(filename)
        next unless partial_file.valid?
        partial_name = partial_file.name_without_underscore
        partials << Partial.new(partial_name, resource.model, nil, context)
      end

      partials
    end


    def initialize(name, resource, channel, context)
      self.name = name
      self.resource = Resource.new(resource)
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
      "sync/#{resource.plural_name}/#{name}"
    end

    def locals
      locals_hash = {}
      locals_hash[resource.name.to_sym] = resource.model

      locals_hash
    end

    def polymorphic_path
      if channel
        "/#{resource.plural_name}/#{channel}"
      else
        resource.polymorphic_path
      end
    end
  end
end
