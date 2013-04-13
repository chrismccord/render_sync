# Sync 
> This is a thought experiment that I hope grows into a viable option for realtime Rails apps.
  The API is in flux, but the core functionality (realtime CRUD) is in place. The goal currently 
  is to test and support common use cases and see how far this approach can be taken and scaled.


Real-time partials with Rails. Sync lets you render partials for models that, with minimal code, 
update in realtime in the browser when changes occur on the server. In practice, the goal 
is to replace `render partial: ''` with `sync partial: ''` and a simple `sync @model, :update` 
in the controller to allow realtime updates without any extra javascript or configuration. 
Initial results are intriguing and I would love to get some real world use-cases and see 
where this approach fits.

Current caveats yet to be implemented but on the immediate road-map:

   - Backgrounding pub/sub in a worker request. Although not completely necessary 
     if your pubsub server is living on the same host, the problem currently is losing
     any state we have in the controller (ivars, methods, session, current_user, etc). 
     Possible solutions maybe be a dead simple API for providing sync partials with a 
     'context' class containing any state needed at render time for use within a worker job.

   - Performance. Currently a model's `app/views/sync/{model_name}` partials are all renderred when publishing 
     updates to the client. Ideally, active listeners/channels could be tracked and skip rendering of any 
     partial that lacks listeners.

   - No parent scoping for listeners on create/sync_new events. Next priority is being able to set a specific channel to listen on (ie. `current_user/comments/new` so we arent publishing global creates.

## Installation

    gem 'sync'
    rails g sync:install
    rackup sync.ru -E production


## Brief Example

View `sync/users/_user_list_row.html.erb`

    <tr>
      <td class="name">
        <%= link_to user do %>
          <%= user.name %>
        <% end %>
      </td>
      <td>
        <%= link_to 'Edit', edit_user_path(user) %>
      </td>
      <td>
        <%= link_to 'Destroy', user, method: :delete, remote: true, data: { confirm: 'Are you sure?' } %>
      </td>
    </tr>

View `users/index.html.erb`

    <h1>Some Users</h1>
    <table>
      <tbody>
        <%= sync partial: 'user_list_row', collection: @users
      </tbody>
    </table>


Controller

    def UsersController < ApplicationController
      … 
      def index
        @users = User.all
      end

      def update
        @user = User.find(params[:id])
        if user.save
        …
        end

        # Sync updates to any partials listening for this user
        sync @user, :update

        redirect_to users_path, notice: "Saved!"
      end

      def destroy
        @user = User.find(params[:id])
        @user.destroy

        # Sync destroy, telling client to remove all dom elements containing this user
        sync @user, :destroy 

        respond_to do |format|
          format.html { redirect_to users_url }
          format.json { head :no_content }
        end
      end
    end

