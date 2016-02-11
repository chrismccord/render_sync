module RenderSync
  module ModelActions
    # Set up instance variable holding the collected sync actions 
    # to be published later on.
    #
    attr_accessor :sync_actions

    # Set up ActiveRecord callbacks to prepare for collecting 
    # publish sync actions and publishing them after commit
    #
    def self.included(base)
      base.class_eval do
        @sync_scope_definitions ||= {}
        
        before_create  :prepare_sync_actions, if: -> { RenderSync::Model.enabled? }
        before_update  :prepare_sync_actions, if: -> { RenderSync::Model.enabled? }
        before_destroy :prepare_sync_actions, if: -> { RenderSync::Model.enabled? }
        
        after_commit   :publish_sync_actions, if: -> { RenderSync::Model.enabled? }
      end
    end
    
    def sync_default_scope
      return nil unless self.class.sync_default_scope
      send self.class.sync_default_scope
    end
    
    private

    def sync_render_context
      RenderSync::Model.context || super
    end
    
    def prepare_sync_actions
      self.sync_actions = []
    end
    
    # Add a new aync action to the list of actions to be published later on
    #
    def add_sync_action(action_name, record, options = {})
      sync_actions.push(Action.new(record, action_name, options))
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
    
    def sync_render_context
      RenderSync::Model.context || super
    end
    
  end
end
