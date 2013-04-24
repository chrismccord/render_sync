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

Then update views realtime with a simple `sync_update(@user)` in the controller without any extra javascript or
configuration.

In addition to real-time updates, Sync also provides:

  - Realtime removal of partials from the DOM when the sync'd model is destroyed in the controller via `sync_destroy(@user)`
  - Realtime appending of newly created model's on scoped channels
  - JavaScript/CoffeeScript hooks to override and extend element updates/appends/removes for partials
  - Support for [Faye](http://faye.jcoglan.com/) and [Pusher](http://pusher.com)

## Requirements

  - Ruby >= 1.9.2
  - Rails >= 3.1


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
  </tbody>
</table>
```


Controller

```ruby
def UsersController < ApplicationController
  …
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

