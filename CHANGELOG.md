# Version 0.3.5 - January 6, 2015

- Removed unnecessary call to `respond_to` since `responders` have been removed from Rails.

# Version 0.3.4 - January 6, 2015

- `#squish` generated HTML
- Fix bug when using `sync @resource` with the `:scope` option

# Version 0.3.0 - March 3, 2014

This release focuses on improving and extending the model DSL for setting up automatic syncing in advanced use cases.

- Adds the ability for advanced channel scoping

  There were multiple feature requests asking for a way to sync differently scoped lists of the same model automatically and interdependently (e.g all todos of a user and all todos of a project). This can now be accomplished by explicitly defining scopes on the model via the new `sync_scope` method:

  ```ruby
  class Todo < ActiveRecord::Base
    belongs_to :project
    belongs_to :user

    sync :all

    sync_scope :by_user(user), -> { where(user_id: user.id) }
    sync_scope :by_project(project), -> { where(project_id: project.id) }
  end
  ```

  and then use these scopes to narrow the rendering of sync partials like this:

  ```erb
  <%= sync partial: "todo", resource: Todo.by_user(@user) %>
  <%= sync_new partial: "todo", resource: Todo.new, scope: Todo.by_user(@user) %>
  ```

  Please take a look at the docs and the readme for a more thorough explanation and examples on how to use this new feature.

- Adds the ability to explicitly update parent associations via `sync_touch`

####Breaking Changes:

- If you're using the scope feature to narrow the syncing of new records in the `sync_new` call, you will now have to add this scope when calling the `sync` helper method as well:

  ```erb
  <%= sync partial: 'todo_comment', collection: @comments, scope: @todo %>
  <%= sync_new partial: 'todo_comment', resource: Comment.new, scope: @todo %>
  ```

  If you're in addition using the controller way of manually syncing partials, you will now also have to add the scope parameter to the sync_destroy call like this:

  ```ruby
  sync_destroy @comment, scope: @comment.todo
  ```

  Why is this?

  Before this version there was only a global destroy channel for every record, so an unscoped `sync_destroy` call was just enough to remove all partials from all subscribed clients when a record has been destroyed. As of 0.3.0 the destroy channel will be used not only to remove  partials when a record is destroyed, but also when partials for that record need to be added to/removed from different sets throughout the application when it is updated.

- The `:scope` parameter for the `sync` method has been replaced with `:default_scope`. Make sure you update your code accordingly. If you're using the default scope feature, be sure to alway add the corresponding option to your views like this:

  ```ruby
  class Todo < ActiveRecord::Base
    belongs_to :organization

    sync :all, default_scope: :organization
  end
  ```

  ```erb
  <%= sync partial: "todo", resource: @todos, default_scope: @organization %>
  <%= sync_new partial: "todo", resource: Todo.new, default_scope: @organization %>
  ```

- The parent model defined by the `:default_scope` parameter will no longer be automatically updated via sync. Please use the new explicit `sync_touch` method instead.

  Old Syntax:
  ```ruby
  class Todo < ActiveRecord::Base
    belongs_to :project
    belongs_to :user

    sync :all, scope: :project
  end
  ```

  New Syntax:
  ```ruby
  class Todo < ActiveRecord::Base
    belongs_to :project
    belongs_to :user

    sync :all, default_scope: :project
    sync_touch :project, :user
  end
  ```

  This will sync all partials of the parent model `project` and `user`, whenever a todo is created/updated/deleted.

# Version 0.2.7 - Feburary 25, 2014

- Fixes https://github.com/chrismccord/sync/issues/54 (Thin complaining about too long query string)

# Version 0.2.3 - June 30, 2013

- Fixed Turbolinks issue where `page:restore` events no longer evaluate script tags in the body. The workaround re-evaluates all sync sript tags on page restore.

# Version 0.2.1 - May 27, 2013

 - Add ability to narrow scope to custom channel for sync_new publishes

Example Usage:

View:
```erb
<%= sync_new partial: 'todo_list_row', resource: Todo.new, scope: [@project, :staff] %>
```

Controller/Model:
```ruby
sync_new @todo, scope: [@project, :staff]
```


# Version 0.2.0 - May 26, 2013

 - Add ability to refetch partial from server to render within session context, ref: https://github.com/chrismccord/sync/issues/44

This solves the issues of syncing partials across different users when the partial requires the session's context (ie. current_user).

Ex:
    View: Add `refetch: true` to sync calls, and place partial file in a 'refetch'
    subdirectory in the model's sync view folder:

The partial file would be located in `app/views/sync/todos/refetch/_list_row.html.erb`
```erb
<% @project.todos.ordered.each do |todo| %>
  <%= sync partial: 'list_row', resource: todo, refetch: true %>
<% end %>
<%= sync_new partial: 'list_row', resource: Todo.new, scope: @project, refetch: true %>
```

*Notes*
While this approach works very well for the cases it's needed, syncing without refetching should be used unless refetching is absolutely necessary for performance reasons. For example,

A sync update request is triggered on the server for a 'regular' sync'd partial with 100 listening clients:
- number of http requests 1
- number of renders 1, pushed out to all 100 clients via pubsub server.


A sync update request is triggered on the server for a 'refetch' sync'd partial with 100 listening clients:
- number of http requests 100
- number of renders 100, rendering each request in clients session context.
