module RenderSync::ConfigHelper
  def include_sync_config(opts = {})
    return unless RenderSync.adapter

    str = ''

    unless opts[:skip_adapter]
      str << %{<script src="#{RenderSync.adapter_javascript_url}" data-turbolinks-eval=false></script>}
    end

    str << %{<script data-turbolinks-eval=false>var RenderSyncConfig = #{RenderSync.config_json};</script>}

    str.html_safe
  end
end
