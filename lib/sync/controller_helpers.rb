module Sync

  module ControllerHelpers

    include Actions


    private

    # ControllerHelpers overrides Action#sync_render_context to use self as
    # context to allow full access to request/response cycle
    # over default abstract Renderer class
    def sync_render_context
      self
    end
  end
end
