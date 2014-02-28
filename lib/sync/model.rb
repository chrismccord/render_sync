module Sync
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

      # Set up automatic syncing of partials when creating, deleting and update of records
      #
      def sync(*actions)
        include ModelActions
        
        if actions.last.is_a? Hash
          @sync_default_scope = actions.last.fetch :default_scope
        end
        @sync_scope_definitions ||= {}
        @sync_touches ||= []
        
        actions = [:create, :update, :destroy] if actions.include? :all
        actions.flatten!

        if actions.include? :create
          before_create  :prepare_sync_actions,               if: -> { Sync::Model.enabled? }
          after_create   :prepare_sync_create, on: :create,   if: -> { Sync::Model.enabled? }
          after_create   :prepare_sync_touches, on: :create,  if: -> { Sync::Model.enabled? }
        end
        
        if actions.include? :update
          before_update  :prepare_sync_actions,               if: -> { Sync::Model.enabled? }
          before_update  :store_state_before_update,          if: -> { Sync::Model.enabled? }
          after_update   :prepare_sync_update, on: :update,   if: -> { Sync::Model.enabled? }
          after_update   :prepare_sync_touches, on: :update,  if: -> { Sync::Model.enabled? }
        end
        
        if actions.include? :destroy
          before_destroy :prepare_sync_actions,               if: -> { Sync::Model.enabled? }
          after_destroy  :prepare_sync_destroy, on: :destroy, if: -> { Sync::Model.enabled? }
          after_destroy  :prepare_sync_touches, on: :destroy, if: -> { Sync::Model.enabled? }
        end

        after_commit :publish_sync_actions,                   if: -> { Sync::Model.enabled? }

      end

      # Set up a sync scope for the model defining a set of records to be updated via sync
      #
      # name - The name of the scope
      # lambda - A lambda defining the scope.
      #    Has to return an ActiveRecord::Relation.
      #
      # You can define the lambda with arguments (see examples). 
      # Note that the naming of the parameters is very important. Only use names of
      # methods or ActiveRecord attributes defined on the model (e.g. user_id). 
      # This way sync will be able to pass changed records to the lambda and track
      # changes to the scope.
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
      # If the collection you want to render is exactly defined be the given scope
      # the scope can be omitted:
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
      # Now when a record changes sync will use the names of the lambda parameters 
      # (project_id and user), get the corresponding attributes from the record (project_id column or
      # user association) and pass it to the lambda. This way sync can identify if a record
      # has been added or removed from a scope and will then publish the changes to subscribers
      # on all scoped channels.
      #
      # Beware that chaining of sync scopes in the view is currently not possible.
      # So the following example would raise an exception:
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
        
        @sync_scope_definitions[name] = Sync::ScopeDefinition.new(self, name, lambda)
        
        singleton_class.send(:define_method, name) do |*args|
          Sync::Scope.new_from_args(@sync_scope_definitions[name], args)
        end        
      end
      
      # Touch an association to be sync'd when this record changes. 
      #
      # Example:
      #
      #   class Todo < ActiveRecord::Base
      #     belongs_to :project
      #
      #     sync :all
      #     sync_touch :project, :user
      #   end
      #
      def sync_touch(*args)
        options = args.extract_options!

        args.each do |arg|
          @sync_touches.push(arg)
        end
      end
      
    end

    module ModelActions
      attr_accessor :sync_actions
      
      def sync_default_scope
        return nil unless self.class.sync_default_scope
        send self.class.sync_default_scope
      end
      
      private

      def sync_render_context
        Sync::Model.context || super
      end
      
      def prepare_sync_actions
        self.sync_actions = []
      end

      def prepare_sync_create
        sync_actions.push Action.new(self, :new, default_scope: sync_default_scope)
        sync_actions.push Action.new(sync_default_scope.reload, :update) if sync_default_scope
        
        sync_scope_definitions.each do |definition|
          scope = Sync::Scope.new_from_model(definition, self)
          if scope.contains?(self)
            sync_actions.push Action.new(self, :new, scope: scope, default_scope: sync_default_scope)
          end
        end
      end

      def prepare_sync_update
        sync_actions.push Action.new(self, :update)

        sync_scope_definitions.each do |definition|
          prepare_sync_update_scope(definition)
        end
      end

      def prepare_sync_destroy
        sync_actions.push Action.new(self, :destroy, default_scope: sync_default_scope)
        sync_actions.push Action.new(sync_default_scope.reload, :update) if sync_default_scope
        
        sync_scope_definitions.each do |definition|
          sync_actions.push Action.new(self, :destroy, scope: Sync::Scope.new_from_model(definition, self), default_scope: sync_default_scope)
        end
      end

      # Creates update actions for subscribers on the sync scope defined by
      # the passed sync scope definition.
      #
      # It compares the state of the record in context of the sync scope before and
      # after the update. If the record has been added to a scope, it publishes a 
      # new partial to the subscribers of that scope. It also sends a destroy action
      # to subscribers of the scope, if the record has been removed from it.
      #
      def prepare_sync_update_scope(definition)
        record_before_update = @record_before_update
        record_after_update = self

        scope_before_update = @scopes_before_update[definition.name][:scope]
        scope_after_update = Sync::Scope.new_from_model(definition, record_after_update)

        old_record_in_old_scope = @scopes_before_update[definition.name][:contains_record]
        old_record_in_new_scope = scope_after_update.contains?(record_before_update)

        new_record_in_new_scope = scope_after_update.contains?(record_after_update)
        new_record_in_old_scope = scope_before_update.contains?(record_after_update)

        # Add destroy action for the old scope (scope_before_update) if this record has left it
        if scope_before_update.valid? && old_record_in_old_scope && !new_record_in_old_scope
          sync_actions.push Action.new(record_before_update, :destroy, scope: scope_before_update, default_scope: sync_default_scope)
        end

        # Add new action for the new scope (scope_after_update) if this record has entered it
        if scope_after_update.valid? && new_record_in_new_scope && (!old_record_in_old_scope || !new_record_in_old_scope)
          sync_actions.push Action.new(record_after_update, :new, scope: scope_after_update, default_scope: sync_default_scope)
        end
      end
      
      def prepare_sync_touches
        sync_touches.each do |touch_association|
          sync_actions.push Action.new(touch_association, :update)
        end
      end
      
      # Run the collected actions on after_commit callback
      # Triggers the syncing of the partials
      #
      def publish_sync_actions
        sync_actions.each(&:perform)
      end
      
      def sync_scope_definitions
        self.class.sync_scope_definitions.values
      end
      
      # Return the associations to be touched after a record change
      # Takes into account that an association itself may have changed during an update call
      # (e.g. project_id has changed). To accomplish this, it uses the stored record
      # from before the update (@record_before_update) and touches that as well as
      # the current association
      #
      def sync_touches
        self.class.sync_touches.map do |touch|
          [send(touch), (@record_before_update.present? ? @record_before_update.send(touch) : nil)].uniq
        end.flatten.compact
      end

      # Stores the current state of the record with its attributes
      # and all sync relations in an instance variable BEFORE the update 
      # command to later be able to check if the record has been 
      # added/removed from sync scopes.
      #
      # Uses ActiveModel::Dirty to track attribute changes
      # (triggered by AR Callback before_update)
      #
      def store_state_before_update
        record = self.class.new(self.attributes.merge(self.changed_attributes))
        record.send("#{self.class.primary_key}=", self.send(self.class.primary_key))
        
        @record_before_update = record
        
        @scopes_before_update = {}
        sync_scope_definitions.each do |definition|
          scope = Sync::Scope.new_from_model(definition, record)
          @scopes_before_update[definition.name] = { 
            scope: scope, 
            contains_record: scope.contains?(record) 
          }
        end
      end

      
    end
  end
end