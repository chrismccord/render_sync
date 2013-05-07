module Sync

  module ControllerHelpers

    include Actions

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def sync_action(*actions)
        options = {}
        options = actions.last if actions.last.is_a? Hash
        if actions.include? :all
          around_filter :enable_sync, options
        else
          around_filter :enable_sync, only: actions
        end
      end
    end


    private

    def enable_sync
      Sync::Model.enable(sync_render_context) do
        yield
      end
    end

    # ControllerHelpers overrides Action#sync_render_context to use self as
    # context to allow full access to request/response cycle
    # over default abstract Renderer class
    def sync_render_context
      self
    end
  end
end
