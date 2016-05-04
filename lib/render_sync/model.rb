module RenderSync
  module Model

    def self.enabled?
      Thread.current["model_sync_enabled"]
    end

    def self.context
      Thread.current["model_sync_context"]
    end

    def self.enable!(context = nil)
      Thread.current["model_sync_enabled"] = true
      Thread.current["model_sync_context"] = context
    end

    def self.disable!
      Thread.current["model_sync_enabled"] = false
      Thread.current["model_sync_context"] = nil
    end

    def self.enable(context = nil)
      enable!(context)
      yield
    ensure
      disable!
    end

    module ClassMethods
      attr_accessor :sync_default_scope, :sync_scope_definitions, :sync_touches

      # Set up automatic syncing of partials when a record of this class is
      # created, updated or deleted. Be sure to wrap your model actions inside
      # a sync_enable block for sync to do its magic.
      #
      def sync(*actions)
        include ModelActions unless include?(ModelActions)
        include ModelChangeTracking unless include?(ModelChangeTracking)
        include ModelRenderSyncing
        
        if actions.last.is_a? Hash
          @sync_default_scope = actions.last.fetch :default_scope
        end
        
        actions = [:create, :update, :destroy] if actions.include? :all
        actions.flatten!

        if actions.include? :create
          after_create  :prepare_sync_create,  if: -> { RenderSync::Model.enabled? }
        end
        
        if actions.include? :update
          after_update  :prepare_sync_update,  if: -> { RenderSync::Model.enabled? }
        end
        
        if actions.include? :destroy
          after_destroy :prepare_sync_destroy, if: -> { RenderSync::Model.enabled? }
        end

      end

      # Set up a sync scope for the model defining a set of records to be 
      # updated via sync
      #
      # name - The name of the scope
      # lambda - A lambda defining the scope.
      #    Has to return an ActiveRecord::Relation.
      #
      # You can define the lambda with arguments (see examples). 
      # Note that the naming of the parameters is very important. Only use 
      # names of methods or ActiveRecord attributes defined on the model (e.g. 
      # user_id). This way sync will be able to pass changed records to the 
      # lambda and track changes to the scope.
      #
      # Example:
      #
      #   class Todo < ActiveRecord::Base
      #     belongs_to :user
      #     belongs_to :project
      #     scope :incomplete, -> { where(complete: false) }
      #
      #     sync :all
      #
      #     sync_scope :complete, -> { where(complete: true) }
      #     sync_scope :by_project, ->(project_id) { where(project_id: project_id) }
      #     sync_scope :my_incomplete_todos, ->(user) { incomplete.where(user_id: user.id) }
      #   end
      #
      # To subscribe to these scopes you would put these lines into your views:
      #
      #   <%= sync partial: "todo", collection: @todos, scope: Todo.complete %>
      #
      # If the collection you want to render is exactly defined be the given 
      # scope the scope can be omitted:
      #
      #   <%= sync partial: "todo", collection: Todo.complete %>
      #
      # For rendering my_incomplete_todos:
      #
      #   <%= sync partial: "todo", collection: Todo.my_incomplete_todos(current_user) %>
      #
      # The render_new call has to look like this:
      #
      #   <%= sync_new partial: "todo", resource: Todo.new, scope: Todo.complete %>
      # 
      # Now when a record changes sync will use the names of the lambda 
      # parameters (project_id and user), get the corresponding attributes from 
      # the record (project_id column or user association) and pass it to the 
      # lambda. This way sync can identify if a record has been added or 
      # removed from a scope and will then publish the changes to subscribers
      # on all scoped channels.
      #
      # Beware that chaining of sync scopes in the view is currently not 
      # possible. So the following example would raise an exception:
      #
      #   <%= sync_new partial: "todo", Todo.new, scope: Todo.mine(current_user).incomplete %>
      #
      # To work around this just create an explicit sync_scope for your problem:
      # 
      #   sync_scope :my_incomplete_todos, ->(user) { incomplete.mine(current_user) }
      #
      # And in the view:
      #
      #   <%= sync_new partial: "todo", Todo.new, scope: Todo.my_incomplete_todos(current_user) %>
      #
      def sync_scope(name, lambda)
        if self.respond_to?(name)
          raise ArgumentError, "invalid scope name '#{name}'. Already defined on #{self.name}"
        end
        
        @sync_scope_definitions[name] = RenderSync::ScopeDefinition.new(self, name, lambda)
        
        singleton_class.send(:define_method, name) do |*args|
          RenderSync::Scope.new_from_args(@sync_scope_definitions[name], args)
        end        
      end
      
      # Register one or more associations to be sync'd when this record changes. 
      #
      # Example:
      #
      #   class Todo < ActiveRecord::Base
      #     belongs_to :project
      #     belongs_to :user
      #
      #     sync :all
      #     sync_touch :project, :user
      #   end
      #
      def sync_touch(*args)
        # Only load Modules and set up callbacks if sync_touch wasn't 
        # called before
        if @sync_touches.blank?
          include ModelActions unless include?(ModelActions)
          include ModelChangeTracking unless include?(ModelChangeTracking)
          include ModelTouching
        
          @sync_touches ||= []
        
          after_create   :prepare_sync_touches, if: -> { RenderSync::Model.enabled? }
          after_update   :prepare_sync_touches, if: -> { RenderSync::Model.enabled? }
          after_destroy  :prepare_sync_touches, if: -> { RenderSync::Model.enabled? }
        end

        options = args.extract_options!
        args.each do |arg|
          @sync_touches.push(arg)
        end
      end
      
    end

  end
end
