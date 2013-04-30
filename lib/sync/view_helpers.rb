module Sync

  module ViewHelpers

    # Surround partial render in script tags, watching for 
    # sync_update and sync_destroy channels from pubsub server
    #
    # options - The Hash of options
    #   partial - The String partial filename without leading underscore
    #   resource - The ActiveModel resource
    #   collection - The Array of ActiveModel resources to use in place of 
    #                single resource
    #
    # Examples
    #   <%= sync partial: 'todo', resource: todo %>
    #   <%= sync partial: 'todo', collection: todos %>
    #
    def sync(options = {})
      channel      = options[:channel]
      partial_name = options.fetch(:partial, channel)
      collection   = options[:collection] || [options.fetch(:resource)]
      
      result = [] 
      collection.each do |resource|
        partial = Sync::Partial.new(partial_name, resource, channel, self)
        result << "
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
        result << partial.render
        result << "
          <script type='text/javascript' data-sync-id='#{partial.selector_end}'>
          </script>
        ".html_safe
      end

      safe_join(result)
    end

    # Setup listener for new resource from sync_new channel, appending
    # partial in place
    #
    # options - The Hash of options
    #   partial - The String partial filename without leading underscore
    #   resource - The ActiveModel resource
    #   scope - The ActiveModel resource to scope the new channel publishes to.
    #           Used for restricting new resource publishes to 'owner' models.
    #           ie, current_user, project, group, etc. When excluded, listens 
    #           for global resource creates.
    # 
    #   direction - The String/Symbol direction to insert rendered partials.
    #               One of :append, :prepend. Defaults to :append
    #
    # Examples
    #   <%= sync_new partial: 'todo', resource: Todo.new, scope: @project %>
    #   <%= sync_new partial: 'todo', resource: Todo.new, scope: @project, direction: :prepend %>
    #  
    def sync_new(options = {})
      partial_name = options.fetch(:partial)
      resource     = options.fetch(:resource)
      scope        = options[:scope]
      direction    = options.fetch :direction, 'append'

      creator = Sync::PartialCreator.new(partial_name, resource, scope, self)
      "
        <script type='text/javascript' data-sync-id='#{creator.selector}'>
          Sync.onReady(function(){
            var creator = new Sync.PartialCreator(
              '#{partial_name}',
              '#{creator.channel}',
              '#{creator.selector}',
              '#{direction}'
            );
            creator.subscribe();
          });
        </script>
      ".html_safe
    end
  end
end
