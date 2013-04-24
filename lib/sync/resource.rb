module Sync
  class Resource
    attr_accessor :model

    def initialize(model)
      self.model = model
    end

    def id
      model.id
    end

    def name
      model.class.model_name.to_s.underscore
    end

    def plural_name
      name.pluralize
    end

    def polymorphic_path
      "/#{plural_name}/#{id}"
    end

    def polymorphic_new_path
      "/#{plural_name}/new"
    end
  end
end
