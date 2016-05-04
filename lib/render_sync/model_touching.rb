module RenderSync
  module ModelTouching

    private

    def prepare_sync_touches
      sync_touches.each do |touch_association|
        add_sync_action :update, touch_association
      end
    end
    
    # Return the associations to be touched after a record change
    # Takes into account that an association itself may have changed during 
    # an update call (e.g. project_id has changed). To accomplish this, it
    # uses the stored record from before the update (@record_before_update) 
    # and touches that as well as the current association
    #
    def sync_touches
      sync_associations = []

      self.class.sync_touches.each do |touch|
        current = send(touch)
        sync_associations.push(current.reload) if current.present?
        
        if @record_before_update.present?
          previous = @record_before_update.send(touch)
          sync_associations.push(previous.reload) if previous.present?
        end
      end

      sync_associations.uniq.compact
    end
        
  end
end
