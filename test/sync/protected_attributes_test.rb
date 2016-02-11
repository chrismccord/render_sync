require_relative '../test_helper'
require 'mocha/setup'
require 'rails/all'

setup_database

describe RenderSync::Model do

  it 'publishes record (create/update/destroy) to main new channel' do
    RenderSync::Model.enable do
      user = UserWithProtectedAttributes.new

      # Create
      user.save!
      assert user.persisted?
      assert_equal 1, user.sync_actions.size

      assert_equal :new, user.sync_actions[0].name
      assert_equal "/user_with_protected_attributes/#{user.id}", user.sync_actions[0].test_path

      # Update
      user.update_attribute(:name, "Foo")
      assert user.persisted?
      assert_equal 1, user.sync_actions.size

      assert_equal :update, user.sync_actions[0].name
      assert_equal "/user_with_protected_attributes/#{user.id}", user.sync_actions[0].test_path

      # Destroy
      user.destroy
      assert user.destroyed?
      assert_equal 1, user.sync_actions.size

      assert_equal :destroy, user.sync_actions[0].name
      assert_equal "/user_with_protected_attributes/#{user.id}", user.sync_actions[0].test_path
    end
  end

end
