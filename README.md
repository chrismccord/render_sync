# Sync [![Build Status](https://img.shields.io/travis/chrismccord/sync.svg)](https://travis-ci.org/chrismccord/sync) [![Code climate](https://img.shields.io/codeclimate/github/chrismccord/sync.svg)](https://codeclimate.com/github/chrismccord/sync) [![Code coverage](https://img.shields.io/codeclimate/coverage/github/chrismccord/sync.svg)](https://codeclimate.com/github/chrismccord/sync) [![gem version](https://img.shields.io/gem/v/sync.svg)](http://rubygems.org/gems/sync)


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

Then update views realtime automatically with the `sync` DSL or with a simple `sync_update(@user)` in the controller without any extra javascript or
configuration.

In addition to real-time updates, Sync also provides:

  - Realtime removal of partials from the DOM when the sync'd model is destroyed in the controller via `sync_destroy(@user)`
  - Realtime appending of newly created model's on scoped channels
  - JavaScript/CoffeeScript hooks to override and extend element updates/appends/removes for partials
  - Support for [Faye](http://faye.jcoglan.com/) and [Pusher](http://pusher.com)

## Requirements

  - Ruby >= 1.9.3
  - Rails 3 >= 3.1 or Rails 4
  - jQuery >= 1.9


## Installation

#### 1) Add the gem to your `Gemfile`

#### Using Faye

```ruby
gem 'faye'
gem 'thin', require: false
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

#### 3) Add sync's configuration script to your application layout `app/views/layouts/application.html.erb`

```erb
<%= include_sync_config %>
```

#### 4) Configure your pubsub server (Faye or Pusher)


#### Using [Faye](http://faye.jcoglan.com/) (self hosted)

Set your configuration in the generated `config/sync.yml` file, using the Faye adapter. Then run Faye alongside your app.

```bash
rackup sync.ru -E production
```

#### Using [Pusher](http://pusher.com) (SaaS)

Set your configuration in the generated `config/sync.yml` file, using the Pusher adapter. No extra process/setup.

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


## 'Automatic' syncing through the sync model DSL

In addition to calling explicit sync actions within controller methods, a
`sync` and `enable_sync` DSL has been added to ActionController::Base and ActiveRecord::Base to automate the syncing
approach in a controlled, threadsafe way.

### Example Model/Controller
```ruby
  class Todo < ActiveRecord::Base
    sync :all
  end
```
```ruby
  class TodosController < ApplicationController
    enable_sync only: [:create, :update, :destroy]
    ...
  end
```

Now, whenever a Todo is created/updated/destroyed inside an action of the `TodosController` changes are automatically pushed to all subscribed clients without manually calling sync actions.

### Updating multiple sets of records with sync scopes

Sometimes you might want to display multiple differently scoped todo lists throughout your application and keep them all in sync. For example:

- A global list with all todos
- A list with all completed todos
- A list with all todos of a user
- A list with all todos of a project
- ...

This was quite tricky to accomplish in previous versions of sync. Well, now this is going to be dead simple with the help of explicit sync scopes. First, define your desired sync scopes on the model with `sync_scope` like this:

```ruby
class Todo < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  sync :all

  sync_scope :active, -> { where(completed: false) }
  sync_scope :completed, -> { where(completed: true) }
end
```

Then in your views display the different sets of todos by passing the `scope` as a parameter like this:

```erb
<%= sync partial: "todo", collection: Todo.active %>
<%= sync_new partial: "todo", resource: Todo.new, scope: Todo.active %>

<%= sync partial: "todo", collection: Todo.completed %>
<%= sync_new partial: "todo", resource: Todo.new, scope: Todo.completed %>
```

Now, whenever a todo is created/updated/destroyed sync will push the appropriate changes to all affected clients. This also works for attribute changes that concern the belonging to a specific scope itself. E.g. if the `completed` flag is set to `true` during an update action sync will automatically push the todo partial to all clients displaying the list of completed todos and remove it from all clients subscribed to the list of active todos.

#### Advanced scoping with parameters

In order to display lists that are dynamically scoped (e.g. by the `current_user` or a `@project` instance variable) you can setup dynamic sync scopes like this:

```ruby
sync_scope :by_user, ->(user) { where(user_id: user.id) }
sync_scope :by_project, ->(project) { where(project_id: project.id) }
```

Note that the naming of the parameters is very important for sync to do its magic. Be sure to only use names of methods, parent associations or ActiveRecord attributes defined on the model (e.g. in this case `user` and `project`). This way sync will be able to detect changes to the scope.

Setup the rendering of the partials in the views with:

```erb
<%= sync partial: "todo", collection: Todo.by_user(current_user) %>
<%= sync_new partial: "todo", resource: Todo.new, scope: Todo.by_user(current_user) %>

<%= sync partial: "todo", collection: Todo.by_project(@project) %>
<%= sync_new partial: "todo", resource: Todo.new, scope: Todo.by_project(@project) %>
```

Beware that chaining of sync scopes in the view is currently not supported. So the following example would not work as expected:

```erb
<%= sync_new partial: "todo", Todo.new, scope: Todo.by_user(current_user).completed %>
```

To work around this just create an explicit sync_scope for your use case:

```ruby
sync_scope :completed_by_user, ->(user) { completed.by_user(current_user) }
```

```erb
<%= sync_new partial: "todo", Todo.new, scope: Todo.completed_by_user(current_user) %>
```

#### Things to keep in mind when using `sync_scope`

Please keep in mind that the more sync scopes you set up the more sync messages will be send over your pubsub adapter. So be sure to keep the number scopes small and remove scopes you are not using.

#### Automatic updating of parent associations

If you want to automatically sync the partials of a parent association whenever a record changes you can use the `sync_touch` method. E.g. if you always want to sync the partials of the associated `user` and `project` just add this line to your `Todo` class:

```ruby
sync_touch :project, :user
```

### Syncing outside of the controller

`Sync::Actions` can be included into any object wishing to perform sync
publishes for a given resource. Instead of using the controller as
context for rendering, a Sync::Renderer instance is used. Since the Renderer
is not part of the request/response/session, it has no knowledge of the
current session (ie. current_user), so syncing from outside the controller
context will require some care that the partial can be rendered within a
sessionless context.

### Example Syncing from a background worker or rails console
```ruby
class MyJob
  include Sync::Actions

  def perform
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
  end
end
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

## Narrowing sync_new scope

Sometimes, you do not want your page to update with every new record. With the `scope` option, you can limit what is being updated on a given page.

One way of using `scope` is by supplying a String or a Symbol. This is useful for example when you want to only show new records for a given locale:

View:
```erb
<%= sync_new partial: 'todo_list_row', resource: Todo.new, scope: I18n.locale %>
```

Controller/Model:
```ruby
sync_new @todo, scope: @todo.locale
```

Another use of `scope` is with a parent resource. This way you can for example update a project page with new todos for this single project:

View:
```erb
<%= sync_new partial: 'todo_list_row', resource: Todo.new, scope: @project %>
```

Controller/Model:
```ruby
sync_new @todo, scope: @project
```

Both approaches can be combined. Just supply an Array of Strings/Symbols and/or parent resources to the `scope` option. Note that the order of elements matters. Be sure to use the same order in your view and in your controller/model.

## Scoping by Partial

If a single resource has a bunch of different sync partials, calling `sync_new` or `sync_update` could be very expensive, as sync would need to render each partial for that resource, even if only one partial would be affected by the update. Because of this, sync allows you to scope these by the name of the partial:

```rb
def UsersController < ApplicationController
  …
  def create
    …
    if @user.save
      sync_new @user, partial: 'users_count'
    end
    …
  end
end
```

In the above example, only the `sync/users/users_count` partial will be rendered and pushed to subscribed clients.

## Refetching Partials

Refetching allows syncing partials across different users when the partial requires the session's context (ie. current_user).

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

## Using with cache_digests (Russian doll caching)

Sync has a custom `DependencyTracker::ERBTracker` that can handle `sync` render calls.
Because the full partial name is not included, it has to guess the location of
your partial based on the name of the `resource` or `collection` passed to it.
See the tests to see how it works. If it doesn't work for you, you can always
use the [explicit "Template Dependency"
markers](https://github.com/rails/cache_digests).

To enable, add to `config/initializers/cache_digests.rb`:

#### Rails 4

```ruby
require 'action_view/dependency_tracker'

ActionView::DependencyTracker.register_tracker :haml, Sync::ERBTracker
ActionView::DependencyTracker.register_tracker :erb, Sync::ERBTracker
```

#### Rails 3 with [cache_digests](https://github.com/rails/cache_digests) gem

```ruby
require 'cache_digests/dependency_tracker'

CacheDigests::DependencyTracker.register_tracker :haml, Sync::ERBTracker
CacheDigests::DependencyTracker.register_tracker :erb, Sync::ERBTracker
```

**Note:** haml support is limited, but it seems to work in most cases.


## Serving Faye over HTTPS (with Thin)

Create a thin configuration file `config/sync_thin.yml` similar to the following:

```yaml
---
port: 4443
ssl: true
ssl_key_file: /path/to/server.pem
ssl_cert_file: /path/to/certificate_chain.pem
environment: production
rackup: sync.ru
```

The `certificate_chain.pem` file should contain your signed certificate, followed by intermediate certificates (if any) and the root certificate of the CA that signed the key.

Next reconfigure the `server` and `adapter_javascript_url` in `config/sync.yml` to look like `https://your.hostname.com:4443/faye` and `https://your.hostname.com:4443/faye/faye.js` respectively.

Finally start up Thin from the project root.

```
thin -C config/sync_thin.yml start
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

## Google detecting not found errors

If you're using [Google Webmaster Tools](https://www.google.com/webmasters/) you may notice that Google detects *lots* of URLs it can't find on your site when using Sync.
This is because Google now attempts to discover URLs in JavaScript and some JavaScript we generate looks a little like a URL to Google.
You can [safely ignore](https://support.google.com/webmasters/answer/2409439?ctx=MCE&ctx=NF) this problem.
