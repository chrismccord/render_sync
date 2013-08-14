require 'pathname'

module Sync
  class Resource
    attr_accessor :model, :scopes

    # Constructor
    #
    # model - The ActiveModel instace for this Resource
    # scopes - The optional scopes to prefix polymorphic paths with.
    #          Can be a Symbol/String, a parent model or an Array
    #          with a combination of both.
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
    #   resource = Resource.new(user, project)
    #   resource.polymorphic_path => "/projects/2/users/1"
    #   resource.polymorphic_new_path => "/projects/2/users/new"
    #
    #   resource = Resource.new(user, [:admin, project])
    #   resource.polymorphic_path => "/admin/projects/2/users/1"
    #   resource.polymorphic_new_path => "/admin/projects/2/users/new"
    def initialize(model, scopes = nil)
      self.model = model
      self.scopes = scopes
    end

    def scopes=(new_scopes)
      new_scopes = [new_scopes] unless new_scopes.nil? or new_scopes.is_a? Array
      @scopes = new_scopes
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

    def scopes_path
      path = Pathname.new('/')
      unless scopes.nil?
        paths = scopes.map do |scope|
          if scope.class.respond_to? :model_name
            Resource.new(scope).polymorphic_path.relative_path_from(path)
          else
            scope.to_s
          end
        end
        path = path.join(*paths)
      end
      path
    end

    # Returns the Pathname for model and parent resource
    def polymorphic_path
      scopes_path.join(plural_name, id.to_s)
    end

    # Returns the Pathname for a new model and parent resource
    def polymorphic_new_path
      scopes_path.join(plural_name, "new")
    end
  end

end
