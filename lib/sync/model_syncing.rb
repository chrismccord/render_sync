module RenderSync
  module ModelRenderSyncing
    
    private

    def prepare_sync_create
      add_sync_action(:new, self, default_scope: sync_default_scope)
      
      sync_scope_definitions.each do |definition|
        scope = RenderSync::Scope.new_from_model(definition, self)
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
        scope = RenderSync::Scope.new_from_model(definition, self)
        if scope.valid?
          add_sync_action :destroy, self, 
            scope: scope, 
            default_scope: sync_default_scope
        end
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
    
  end
end
