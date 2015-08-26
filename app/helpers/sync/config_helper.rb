module Sync::ConfigHelper
  def include_sync_config(opts = {})
    return unless Sync.adapter

    vars = {
      server: Sync.server,
      api_key: Sync.api_key,
      pusher_ws_host: Sync.pusher_ws_host,
      pusher_ws_port: Sync.pusher_ws_port,
      pusher_wss_port: Sync.pusher_wss_port,
      pusher_encrypted: Sync.pusher_encrypted,
      adapter: Sync.adapter
    }.reject { |k, v| v.nil? }

    str = ''

    unless opts[:skip_adapter]
      str << %{<script src="#{Sync.adapter_javascript_url}" data-turbolinks-eval=false></script>}
    end

    str << %{<script data-turbolinks-eval=false>var SyncConfig = #{vars.to_json};</script>}

    str.html_safe
  end
end
