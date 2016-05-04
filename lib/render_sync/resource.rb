require 'pathname'

module RenderSync
  class Resource
    attr_accessor :model, :scopes

    # Constructor
    #
    # model - The ActiveModel instace for this Resource
    # scopes - The optional scopes to prefix polymorphic paths with.
    #          Can be a Symbol/String, a parent model or an RenderSync::Scope
    #          or an Array with any combination.
    #
    # Examples
    #
    #   class User < ActiveRecord::Base
    #     sync :all
    #     sync_scope :cool, -> { where(cool: true) }
    #     sync_scope :in_group, ->(group) { where(group_id: group.id) }
    #   end
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
    #   resource = Resource.new(user, User.cool)
    #   resource.polymorphic_path => "/cool/users/2"
    #   resource.polymorphic_new_path => "/cool/users/new"
    #
    #   resource = Resource.new(user, User.in_group(group))
    #   resource.polymorphic_path => "/in_group/group/3/users/2"
    #   resource.polymorphic_new_path => "/in_group/group/3/users/new"
    #
    #   resource = Resource.new(user, [:admin, User.cool, User.in_group(group)])
    #   resource.polymorphic_path => "admin/cool/in_group/group/3/users/2"
    #   resource.polymorphic_new_path => "admin/cool/in_group/group/3/users/new"
    #
    #   resource = Resource.new(user, [:admin, project])
    #   resource.polymorphic_path => "/admin/projects/2/users/1"
    #   resource.polymorphic_new_path => "/admin/projects/2/users/new"
    #
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
    
    def base_name
      name.split('/').last
    end

    def plural_name
      name.pluralize
    end

    def scopes_path
      path = Pathname.new('/')
      unless scopes.nil?
        paths = scopes.map do |scope|
          if scope.is_a?(RenderSync::Scope)
            scope.polymorphic_path.relative_path_from(path)
          elsif scope.class.respond_to? :model_name
            Resource.new(scope).polymorphic_path.relative_path_from(path)
          else
            scope.to_s
          end
        end
        path = path.join(*paths)
      end
      path
    end

    # Returns an unscoped Pathname for the model (e.g. /users/1)
    def model_path
      Pathname.new('/').join(plural_name, id.to_s)
    end

    # Returns the scoped Pathname for the model (e.g. /users/1/todos/2)
    def polymorphic_path
      scopes_path.join(plural_name, id.to_s)
    end

    # Returns the scoped Pathname for a new model (e.g. /users/1/todos/new)
    def polymorphic_new_path
      scopes_path.join(plural_name, "new")
    end
  end

end
