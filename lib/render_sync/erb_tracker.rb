module RenderSync
  tracker_class = nil
  begin
    require 'action_view/dependency_tracker'
    tracker_class = ActionView::DependencyTracker::ERBTracker
  rescue LoadError
    begin
      require 'cache_digests/dependency_tracker'
      tracker_class = CacheDigests::DependencyTracker::ERBTracker
    rescue LoadError
    end
  end

  if tracker_class
    class ERBTracker < tracker_class
      # Matches:
      #   sync partial: "comment", collection: commentable.comments
      #   sync partial: "comment", resource: comment
      SYNC_DEPENDENCY = /
        sync(?:_new)?\s*                         # sync or sync_new, followed by optional whitespace
        \(?\s*                                   # start an optional parenthesis for the sync call
        (?:partial:|:partial\s+=>)\s*            # naming the partial, used with collection
        ["']([a-z][a-z_\/]+)["']\s*              # the template name itself -- 1st capture
        ,\s*                                     # comma separating parameters
        :?(?:resource|collection)(?::|\s+=>)\s*  # resource or collection identifier
        @?(?:[a-z]+\.)*([a-z]+)                  # the resource or collection itself -- 2nd capture
      /x

      def self.call(name, template)
        new(name, template).dependencies
      end

      def dependencies
        (sync_dependencies + super).uniq
      end

      private

      def source
        template.source
      end

      def sync_dependencies
        source.scan(SYNC_DEPENDENCY).
          collect { |template, resource| "sync/#{resource.pluralize}/#{template}" }
      end
    end
  end
end
