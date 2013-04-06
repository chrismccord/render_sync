module Sync

  module ViewHelpers
    def sync(options = {})
      channel = options[:channel]
      partial_name = options[:partial] || channel
      collection = options[:collection] || [options.fetch(:resource)]
      if collection
        collection.each do |resource|
          partial = Sync::Partial.new(partial_name, resource, channel, self)
          concat "
            <script type='text/javascript' data-sync-id='#{partial.selector_start}'>
              $(function(){
                var partial = new Sync.Partial(
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
      end

      nil
    end

    def sync_new(options = {})
      partial_name = options.fetch(:partial)
      resource = options.fetch(:resource)
      partial_creator = Sync::PartialCreator.new(partial_name, resource, self)
      concat "
        <script type='text/javascript' data-sync-id='#{partial_creator.selector}'>
          $(function(){
            var partial_creator = new Sync.PartialCreator(
              '#{partial_creator.channel}',
              '#{partial_creator.selector}'
            );
            partial_creator.subscribe();
          });
        </script>
      ".html_safe

      nil
    end
  end
end