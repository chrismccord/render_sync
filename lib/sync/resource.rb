require 'pathname'

module Sync
  class Resource
    attr_accessor :model, :channel, :parent

    # Constructor
    #
    # model - The ActiveModel instace for this Resource
    # channel - The optional scoped channel to prefix polymorphic paths for.
    #           One of String/Symbol or Array of String/Symbol.
    #
    # Examples
    #
    #   user = User.find(1)
    #
    #   resource = Resource.new(user)
    #   resource.polymorphic_path => "/users/1"
    #   resource.polymorphic_new_path => "/users/new"
    #
    #   resource = Resource.new(user, :admin)
    #   resource.polymorphic_path => "/admin/users/1"
    #   resource.polymorphic_new_path => "/admin/users/new"
    #
    #   resource = Resource.new(user, [:staff, :restricted])
    #   resource.polymorphic_path => "/staff/restricted/users/1"
    #   resource.polymorphic_new_path => "/staff/restricted/users/new"
    #    
    def initialize(model, channel = nil)
      self.model = model
      self.channel = if channel.is_a? Array
        channel.join("/")
      else
        channel
      end
    end

    # The Resource to use for prefixing polymorphic paths with parent paths.
    # Default NullResource.new
    #
    # Examples
    #
    #   user = User.find(1)
    #   project = Project.find(123)
    #
    #   resource = Resource.new(user)
    #   resource.parent = Resource.new(project)
    #   resource.polymorphic_path => "/projects/123/users/1"
    #   resource.polymorphic_new_path => "/projects/123/users/new"
    #
    def parent
      @parent || NullResource.new
    end

    def id
      model.id
    end

    def name
      model.class.model_name.to_s.underscore.model.split('/').last
    end

    def plural_name
      name.pluralize
    end

    # Returns the Pathname for model and parent resource
    def polymorphic_path
      parent.polymorphic_path.join(channel.to_s, plural_name, id.to_s)
    end

    # Returns the Pathname for a new model and parent resource
    def polymorphic_new_path
      parent.polymorphic_path.join(channel.to_s, plural_name, "new")
    end
  end

  class NullResource < Resource

    def initialize
    end

    def polymorphic_path
      Pathname.new("/")
    end

    def polymorphic_new_path
      Pathname.new("/")
    end
  end
end
