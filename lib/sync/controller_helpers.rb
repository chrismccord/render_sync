module RenderSync

  module ControllerHelpers

    include Actions

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def enable_sync(options = {})
        around_filter :enable_sync, options
      end
    end


    private

    def enable_sync
      RenderSync::Model.enable(sync_render_context) do
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
