module RenderSync
  class RefetchModel

    def self.find_by_class_name_and_id(resource_name, id)      
      class_name = resource_name.to_s.classify
      class_name.safe_constantize.find(id) if supported_classes.include?(class_name)
    rescue
      nil
    end

    def self.supported_classes
      Thread.current["sync_refetch_classes"] = nil if Rails.env.development?
      
      Thread.current["sync_refetch_classes"] ||= begin
        Dir["app/views/sync/*/refetch"].collect{|path|
          File.basename(path.gsub(/\/refetch$/, '')).classify
        }.reject{|clazz| clazz.nil? }
      end
    end
  end
end
