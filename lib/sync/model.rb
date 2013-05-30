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
      attr_accessor :sync_scope

      def sync(*actions)
        include Sync::Actions
        include ModelActions
        if actions.last.is_a? Hash
          @sync_scope = actions.last.fetch :scope
        end
        actions = [:create, :update, :destroy] if actions.include? :all
        actions.flatten!

        if actions.include? :create
          after_commit :publish_sync_create, on: :create, if: -> { Sync::Model.enabled? }
        end
        if actions.include? :update
          after_commit :publish_sync_update, on: :update, if: -> { Sync::Model.enabled? }
        end
        if actions.include? :destroy
          after_commit :publish_sync_destroy, on: :destroy, if: -> { Sync::Model.enabled? }
        end
      end
    end

    module ModelActions
      def sync_scope
        return nil unless self.class.sync_scope
        send self.class.sync_scope
      end

      def sync_render_context
        Sync::Model.context || super
      end

      def publish_sync_create        
        sync_new self, scope: sync_scope
        sync_update sync_scope.reload if sync_scope
      end

      def publish_sync_update        
        if sync_scope
          sync_update [self, sync_scope.reload]
        else
          sync_update self
        end
      end

      def publish_sync_destroy        
        sync_destroy self
        sync_update sync_scope.reload if sync_scope
      end
    end
  end
end