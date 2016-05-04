module RenderSync
  class RefetchPartial < Partial

    def self.all(model, context, scope = nil)
      resource = Resource.new(model)

      Dir["#{RenderSync.views_root}/#{resource.plural_name}/refetch/_*.*"].map do |partial|
        partial_name = File.basename(partial)
        RefetchPartial.new(partial_name[1...partial_name.index('.')], resource.model, scope, context)
      end
    end

    def self.find(model, partial_name, context)
      resource = Resource.new(model)
      plural_name = resource.plural_name
      partial = Dir["#{RenderSync.views_root}/#{plural_name}/refetch/_#{partial_name}.*"].first
      return unless partial
      RefetchPartial.new(partial_name, resource.model, nil, context)
    end

    def self.find_by_authorized_resource(model, partial_name, context, auth_token)
      partial = find(model, partial_name, context)
      return unless partial && partial.authorized?(auth_token)

      partial
    end

    def message(action)
      RenderSync.client.build_message channel_for_action(action), refetch: true
    end

    def creator_for_scope(scope)
      RefetchPartialCreator.new(name, resource.model, scope, context)
    end


    private

    def path
      "sync/#{resource.plural_name}/refetch/#{name}"
    end
  end
end
