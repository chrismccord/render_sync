module Sync
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
    
    def add_sync_action(action_name, record, options = {})
      sync_actions.push(Action.new(record, action_name, options))
    end

    def prepare_sync_create
      add_sync_action(:new, self, default_scope: sync_default_scope)
      
      sync_scope_definitions.each do |definition|
        scope = Sync::Scope.new_from_model(definition, self)
        if scope.contains?(self)
          add_sync_action :new, self, scope: scope, default_scope: sync_default_scope
        end
      end
    end

    def prepare_sync_update
      add_sync_action :update, self

      sync_scope_definitions.each do |definition|
        prepare_sync_update_scope(definition)
      end
    end

    def prepare_sync_destroy
      add_sync_action :destroy, self, default_scope: sync_default_scope
      
      sync_scope_definitions.each do |definition|
        add_sync_action :destroy, self, 
          scope: Sync::Scope.new_from_model(definition, self), 
          default_scope: sync_default_scope
      end
    end

    # Creates update actions for subscribers on the sync scope defined by
    # the passed sync scope definition.
    #
    # It compares the state of the record in context of the sync scope before 
    # and after the update. If the record has been added to a scope, it 
    # publishes a new partial to the subscribers of that scope. It also sends 
    # a destroy action to subscribers of the scope, if the record has been 
    # removed from it.
    #
    def prepare_sync_update_scope(scope_definition)
      # Add destroy action for the old scope (scope_before_update) 
      # if this record has left it
      if left_old_scope?(scope_definition)
        add_sync_action :destroy, record_before_update, 
          scope: scope_before_update(scope_definition), 
          default_scope: sync_default_scope
      end

      # Add new action for the new scope (scope_after_update) if this record has entered it
      if entered_new_scope?(scope_definition)
        add_sync_action :new, record_after_update, 
          scope: scope_after_update(scope_definition), 
          default_scope: sync_default_scope
      end
    end
    
    def prepare_sync_touches
      sync_touches.each do |touch_association|
        add_sync_action :update, touch_association
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
    # Takes into account that an association itself may have changed during 
    # an update call (e.g. project_id has changed). To accomplish this, it
    # uses the stored record from before the update (@record_before_update) 
    # and touches that as well as the current association
    #
    def sync_touches
      self.class.sync_touches.map do |touch|
        [send(touch), (@record_before_update.present? ? @record_before_update.send(touch) : nil)].uniq
      end.flatten.compact
    end
    
  end

end