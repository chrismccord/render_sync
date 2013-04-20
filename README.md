# Sync 
> This started as a thought experiment that is growing into a viable option for realtime Rails apps without ditching 
  the standard rails stack that we love and are so productive with for a heavy client side MVC framework.


Real-time partials with Rails. Sync lets you render partials for models that, with minimal code, 
update in realtime in the browser when changes occur on the server. In practice, one simply only needs to replace 

    <%= render partial: 'user_row', locals: {user: @user} %>
  
with 

    <%= sync partial: 'user_row', resource: @user %>
    
Then update views realtime with a simple `sync_update(@user)` in the controller without any extra javascript or 
configuration. 

In additoinal to real-time udpates, Sync also provides:

  - Realtime removal of partials from the DOM when the sync'd model is destroyed in the controller via `sync_destroy(@user)`
  - Realtime appending of newly created model's on scoped channels
  - JavaScript/CoffeeScript hooks to override and extend element updates/appends/removes for partials
  - Support for [Faye](http://faye.jcoglan.com/) and [Pusher](http://pusher.com)


## Installation

#### 1) Add the gem to your `Gemfile`

    gem 'sync'
    $ bundle
    $ rails g sync:install
    
#### 2) Require sync in your asset javascript manifest `app/assets/javascripts/application.js`:
    
    //= require sync

#### 3) Configure your pubsub server (Faye or Pusher)

#### Using [Faye](http://faye.jcoglan.com/) (self hosted)

Set your configuration in the generated config/sync.yml file, using the Faye adapter. Then run Faye alongside your app.
    
    rackup sync.ru -E production
    
#### Using [Pusher](http://pusher.com) (SaaS)

Set your configuration in the generated `config/sync.yml` file, using the Pusher adapter. No extra process/setup.
  

## Brief Example

View `sync/users/_user_list_row.html.erb`

    <tr>
      <td><%= link_to user.name, user %></td>
      <td><%= link_to 'Edit', edit_user_path(user) %></td>
      <td><%= link_to 'Destroy', user, method: :delete, remote: true, data: { confirm: 'Are you sure?' } %></td>
    </tr>

View `users/index.html.erb`

    <h1>Some Users</h1>
    <table>
      <tbody>
        <%= sync partial: 'user_list_row', collection: @users %>
      </tbody>
    </table>


Controller

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

