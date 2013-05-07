# Sync
> This started as a thought experiment that is growing into a viable option for realtime Rails apps without ditching
  the standard rails stack that we love and are so productive with for a heavy client side MVC framework.


Real-time partials with Rails. Sync lets you render partials for models that, with minimal code,
update in realtime in the browser when changes occur on the server.

#### Watch a screencast to see it in action
[![See it in action](http://chrismccord.com/images/sync/video_thumb.png)](http://chrismccord.com/blog/2013/04/21/sync-realtime-rails-partials/)

In practice, one simply only needs to replace:

```erb
<%= render partial: 'user_row', locals: {user: @user} %>
```

with:

```erb
<%= sync partial: 'user_row', resource: @user %>
```

Then update views realtime automatically with the `sync` DSL or with a with a simple `sync_update(@user)` in the controller without any extra javascript or
configuration.

In addition to real-time updates, Sync also provides:

  - Realtime removal of partials from the DOM when the sync'd model is destroyed in the controller via `sync_destroy(@user)`
  - Realtime appending of newly created model's on scoped channels
  - JavaScript/CoffeeScript hooks to override and extend element updates/appends/removes for partials
  - Support for [Faye](http://faye.jcoglan.com/) and [Pusher](http://pusher.com)

## Requirements

  - Ruby >= 1.9.2
  - Rails >= 3.1
  - jQuery >= 1.9


## Installation

#### 1) Add the gem to your `Gemfile`

#### Using Faye

```ruby
gem 'faye'
gem 'thin'
gem 'sync'
```

#### Using Pusher

```ruby
gem 'pusher'
gem 'sync'
```

#### Install

```bash
$ bundle
$ rails g sync:install
```

#### 2) Require sync in your asset javascript manifest `app/assets/javascripts/application.js`:

```javascript
//= require sync
```

#### 3) Add the pubsub adapter's javascript to your application layout `app/views/layouts/application.html.erb`

```erb
<%= javascript_include_tag Sync.adapter_javascript_url %>
```

#### 4) Configure your pubsub server (Faye or Pusher)


#### Using [Faye](http://faye.jcoglan.com/) (self hosted)

Set your configuration in the generated `config/sync.yml` file, using the Faye adapter. Then run Faye alongside your app.

```bash
rackup sync.ru -E production
```

#### Using [Pusher](http://pusher.com) (SaaS)

Set your configuration in the generated `config/sync.yml` file, using the Pusher adapter. No extra process/setup.


##### Determine if your configuration can run in async mode or not (true by default in sync.yml)

By Default, Sync runs in async mode, meaning all http post requests to the pubsub server will run in an
eventmachine-http request, bypassing the need for a background job/worker and allowing the controller
request-response times to remain unaffected by sync publishes. Running in async mode requires either an evented
webserver like `thin` or manually running an eventmachine process in a seperate thread. For example, async mode
works perfectly with `unicorn` using a configuration such as:

```ruby
# config/unicorn.rb
worker_processes 3
preload_app true
timeout 30

before_fork do |server, worker|
  ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)
  EM.stop if defined?(EM) && EM.reactor_running?
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
  Thread.new { EM.run }
end
```

## Current Caveats
The current implementation uses a DOM range query (jQuery's `nextUntil`) to match your partial's "element" in 
the DOM. The way this selector works requires your sync'd partial to be wrapped in a root level html tag for that partial file. 
For example, this parent view/sync partial approach would *not* work:

Given the sync partial `_todo_row.html.erb`:

```erb
Title:
<%= link_to todo.title, todo %>
```

And the parent view:

```erb
<table>
  <tbody>
    <tr>
      <%= sync partial: 'todo_row', resource: @todo %>
    </tr>
  </tbody>
</table>
```

##### The markup *would need to change to*:


sync partial `_todo_row.html.erb`:

```erb
<tr> <!-- root level container for the partial required here -->
  Title:
  <%= link_to todo.title, todo %>
</tr>
```

And the parent view changed to:

```erb
<table>
  <tbody>
    <%= sync partial: 'todo_row', resource: @todo %>
  </tbody>
</table>
```

I'm currently investigating true DOM ranges via the [Range](https://developer.mozilla.org/en-US/docs/DOM/range) object.


## 'Automatic' syncing through the sync DSL

In addition to calling explicit sync actions within controller methods, a
`sync` and `enable_sync` DSL has been added to ActionController::Base and ActiveRecord::Base to automate the syncing 
approach in a controlled, threadsafe way.

### Example Controller/Model
```ruby
  class TodosController < ApplicationController

    enable_sync only: [:create, :update, :destroy]
    ...
  end

  class Todo < ActiveRecord::Base

    belongs_to :project, counter_cache: true
    has_many :comments, dependent: :destroy

    sync :all, scope: :project

  end
```

### Syncing outside of the controller

`Sync::Actions` can be included into any object wishing to perform sync
publishes for a given resource. Instead of using the the controller as
context for rendering, a Sync::Renderer instance is used. Since the Renderer
is not part of the request/response/session, it has no knowledge of the
current session (ie. current_user), so syncing from outside the controller
context will require some care that the partial can be rendered within a
sessionless context.

### Example Syncing from a background worker or rails console
```ruby
 # Inside some script/worker
  Sync::Model.enable do
    Todo.first.update title: "This todo will be sync'd on save"
  end
  Todo.first.update title: "This todo will NOT be sync'd on save"

  Sync::Model.enable!
  Todo.first.update title: "This todo will be sync'd on save"
  Todo.first.update title: "This todo will be sync'd on save"
  Todo.first.update title: "This todo will be sync'd on save"
  Sync::Model.disable!
  Todo.first.update title: "This todo will NOT be sync'd on save"
```
  
## Custom Sync Views and javascript hooks

Sync allows you to hook into and override or extend all of the actions it performs when updating partials on the client side. When a sync partial is rendered, sync will instantiate a javascript View class based on the following order of lookup:

 1. The camelized version of the concatenated snake case resource
    and partial names.
 2. The camelized version of the snake cased partial name.

#### Examples

partial name 'list_row', resource name 'todo', order of lookup:

 1. Sync.TodoListRow
 2. Sync.ListRow
 3. Sync.View (Default fallback)


For example, if you wanted to fade in/out a row in a sync'd todo list instead of the Sync.View default of instant insert/remove:

```coffeescript
class Sync.TodoListRow extends Sync.View

  beforeInsert: ($el) ->
    $el.hide()
    @insert($el)

  afterInsert: -> @$el.fadeIn 'slow'

  beforeRemove: -> @$el.fadeOut 'slow', => @remove()

```

## Brief Example or [checkout an example application](https://github.com/chrismccord/sync_example)

View `sync/users/_user_list_row.html.erb`

```erb
<tr>
  <td><%= link_to user.name, user %></td>
  <td><%= link_to 'Edit', edit_user_path(user) %></td>
  <td><%= link_to 'Destroy', user, method: :delete, remote: true, data: { confirm: 'Are you sure?' } %></td>
</tr>
```

View `users/index.html.erb`

```erb
<h1>Some Users</h1>
<table>
  <tbody>
    <%= sync partial: 'user_list_row', collection: @users %>
    <%= sync_new partial: 'user_list_row', resource: User.new, direction: :append %>
  </tbody>
</table>
```


Controller

```ruby
def UsersController < ApplicationController
  …
  def create
    @user = User.new(user_params)
    if @user.save
      sync_new @user      
    end
    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end

  def update
    @user = User.find(params[:id])
    if user.save
    …
    end

    # Sync updates to any partials listening for this user
    sync_update @user

    redirect_to users_path, notice: "Saved!"
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy

    # Sync destroy, telling client to remove all dom elements containing this user
    sync_destroy @user

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
end
```

