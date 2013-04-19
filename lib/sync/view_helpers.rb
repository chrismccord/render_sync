module Sync

  module ViewHelpers
    def sync(options = {})
      channel      = options[:channel]
      partial_name = options.fetch(:partial, channel)
      collection   = options[:collection] || [options.fetch(:resource)]
      
      collection.each do |resource|
        partial = Sync::Partial.new(partial_name, resource, channel, self)
        concat "
          <script type='text/javascript' data-sync-id='#{partial.selector_start}'>
            Sync.onReady(function(){
              var partial = new Sync.Partial(
                '#{partial.name}',
                '#{partial.channel_for_action(:update)}',
                '#{partial.channel_for_action(:destroy)}',
                '#{partial.selector_start}',
                '#{partial.selector_end}'
              );
              partial.subscribe();
            });
          </script>
        ".html_safe
        concat(partial.render)
        concat "
          <script type='text/javascript' data-sync-id='#{partial.selector_end}'>
          </script>
        ".html_safe
      end

      nil
    end

    def sync_new(options = {})
      partial_name = options.fetch(:partial)
      resource     = options.fetch(:resource)
      scope        = options[:scope]
      creator = Sync::PartialCreator.new(partial_name, resource, scope, self)
      concat "
        <script type='text/javascript' data-sync-id='#{creator.selector}'>
          Sync.onReady(function(){
            var creator = new Sync.PartialCreator(
              '#{partial_name}',
              '#{creator.channel}',
              '#{creator.selector}'
            );
            creator.subscribe();
          });
        </script>
      ".html_safe

      nil
    end
  end
end