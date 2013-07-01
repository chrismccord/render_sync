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
