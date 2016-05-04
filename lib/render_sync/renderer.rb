module RenderSync
  class Renderer

    attr_accessor :context

    def initialize
      self.context = ApplicationController.new.view_context
      self.context.instance_eval do
        def url_options
          ActionMailer::Base.default_url_options
        end
      end
    end

    def render_to_string(options)
      context.render(options)
    end
  end
end
