module RenderSync
  module ModelChangeTracking
    private
    # Set up callback to store record and sync scope states prior
    # the update action
    def self.included(base)
      base.class_eval do
        before_update :store_state_before_update, if: -> { RenderSync::Model.enabled? }
      end
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
      record = self.dup
      changed_attributes.each do |key, value|
        record.send("#{key}=", value)
      end
      record.send("#{self.class.primary_key}=", self.send(self.class.primary_key))
      
      @record_before_update = record
      
      @scopes_before_update = {}
      sync_scope_definitions.each do |definition|
        scope = RenderSync::Scope.new_from_model(definition, record)
        @scopes_before_update[definition.name] = { 
          scope: scope, 
          contains_record: scope.contains?(record) 
        }
      end
    end

    # Checks if this record has left the old scope defined by the passed scope
    # definition throughout the update process
    #
    def left_old_scope?(definition)
      scope_before_update(definition).valid? \
        && old_record_in_old_scope?(definition) \
        && !new_record_in_old_scope?(definition)
    end

    # Checks if this record has entered the new (possibly changed) scope
    # defined by the passed scope definition throughout the update process
    #
    def entered_new_scope?(definition)
      scope_after_update(definition).valid? \
        && new_record_in_new_scope?(definition) \
        && !remained_in_old_scope?(definition)
    end

    # Return the instance (state) of this record from before the update
    # (which was previously stored by #store_state_before_update)
    #
    def record_before_update
      @record_before_update
    end
    
    def record_after_update
      self
    end

    def remained_in_old_scope?(definition)
      old_record_in_old_scope?(definition) && new_record_in_old_scope?(definition)
    end   
    
    def scope_before_update(definition)
      @scopes_before_update[definition.name][:scope]
    end
    
    def scope_after_update(definition)
      RenderSync::Scope.new_from_model(definition, record_after_update)
    end
    
    def old_record_in_old_scope?(definition)
      @scopes_before_update[definition.name][:contains_record]
    end
    
    def old_record_in_new_scope?(definition) 
      scope_after_update(definition).contains?(record_before_update)
    end
    
    def new_record_in_new_scope?(definition)
      scope_after_update(definition).contains?(record_after_update)
    end
 
    def new_record_in_old_scope?(defintion)
      scope_before_update(defintion).contains?(record_after_update)
    end
    
  end
end
