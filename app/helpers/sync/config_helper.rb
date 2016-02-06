module Sync::ConfigHelper
  def include_sync_config(opts = {})
    return unless Sync.adapter

    str = ''

    unless opts[:skip_adapter]
      str << %{<script src="#{Sync.adapter_javascript_url}" data-turbolinks-eval=false></script>}
    end

    str << %{<script data-turbolinks-eval=false>var SyncConfig = #{Sync.config_json};</script>}

    str.html_safe
  end
end
