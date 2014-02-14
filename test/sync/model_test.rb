require_relative '../test_helper'
require 'mocha/setup'
require 'rails/all'

setup_database

describe Sync::Model do

  it 'can is disabled by default' do
    refute Sync::Model.enabled?
  end

  it 'can be enabled and disabled' do
    Sync::Model.enable!
    assert Sync::Model.enabled?

    Sync::Model.disable!
    refute Sync::Model.enabled?
  end

  it 'can be given a block to have things enabled in' do
    Sync::Model.enable do
      assert Sync::Model.enabled?
    end

    refute Sync::Model.enabled?
  end

  describe 'syncing of model changes to all listening channels' do
    it 'publishes record (create/update/destroy) to main new channel' do
      Sync::Model.enable do
        user = UserWithoutScopes.new
        
        # Create
        user.save!
        assert user.persisted?
        assert_equal 1, user.sync_actions.size
        
        assert_equal :new, user.sync_actions[0].name
        assert_equal "/user_without_scopes/#{user.id}", user.sync_actions[0].test_path
      
        # Update
        user.update_attributes!(name: "Foo")
        assert user.persisted?
        assert_equal 1, user.sync_actions.size
        
        assert_equal :update, user.sync_actions[0].name
        assert_equal "/user_without_scopes/#{user.id}", user.sync_actions[0].test_path
        
        # Destroy
        user.destroy
        assert user.destroyed?
        assert_equal 1, user.sync_actions.size
        
        assert_equal :destroy, user.sync_actions[0].name
        assert_equal "/user_without_scopes/#{user.id}", user.sync_actions[0].test_path
      end
    end

    it 'publishes record with default scope to scope channel and parent channel' do
      Sync::Model.enable do
        
        # Create
        group = Group.create!
        user = UserWithDefaultScope.new(group: group)
        user.save!
        
        assert user.persisted?
        assert_equal 2, user.sync_actions.size
        
        assert_equal :new, user.sync_actions[0].name
        assert_equal "/groups/#{group.id}/user_with_default_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :update, user.sync_actions[1].name
        assert_equal "/groups/#{group.id}", user.sync_actions[1].test_path

        # Update
        user.update_attributes!(name: "Foo")
        
        assert user.persisted?
        assert_equal 1, user.sync_actions.size
        
        assert_equal :update, user.sync_actions[0].name
        assert_equal "/groups/#{group.id}/user_with_default_scopes/#{user.id}", user.sync_actions[0].test_path

        # Destroy
        user.destroy
        
        assert user.destroyed?
        assert_equal 2, user.sync_actions.size
        
        assert_equal :destroy, user.sync_actions[0].name
        assert_equal "/groups/#{group.id}/user_with_default_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :update, user.sync_actions[1].name
        assert_equal "/groups/#{group.id}", user.sync_actions[1].test_path

      end
    end

    it 'publishes record with simple named sync scope' do
      Sync::Model.enable do
        
        # Create user not in scope (age > 90)
        user = UserWithSimpleScope.new(age: 85)
        user.save!
        assert_equal 1, user.sync_actions.size
        
        assert_equal :new, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        # Create user which in scope old (age >= 90)
        user = UserWithSimpleScope.new(age: 95)
        user.save!
        assert_equal 2, user.sync_actions.size
        
        assert_equal :new, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :new, user.sync_actions[1].name
        assert_equal "/old/user_with_simple_scopes/#{user.id}", user.sync_actions[1].test_path
        
        # Update of independent attribute name
        user.update_attributes!(name: "Foo")
        assert !user.changed?
        assert_equal 2, user.sync_actions.size
        
        assert_equal :update, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :update, user.sync_actions[1].name
        assert_equal "/old/user_with_simple_scopes/#{user.id}", user.sync_actions[1].test_path

        # Update of dependent attribute age, so that the record no longer falls into the scope
        # and has to be destroyed on that channel
        user.update_attributes!(age: 80)
        assert !user.changed?
        assert_equal 2, user.sync_actions.size
        
        assert_equal :update, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :destroy, user.sync_actions[1].name
        assert_equal "/old/user_with_simple_scopes/#{user.id}", user.sync_actions[1].test_path

        # Update of dependent attribute age, so that the record will fall into the scope
        # and has to be destroyed on that channel
        user.update_attributes(age: 100)
        
        assert !user.changed?
        assert_equal 2, user.sync_actions.size
        
        assert_equal :update, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :new, user.sync_actions[1].name
        assert_equal "/old/user_with_simple_scopes/#{user.id}", user.sync_actions[1].test_path
        
      end
    end
    
  end

  it 'does not have a sync default scope if it is not specified' do
    user = User.new name: "Foo"
    assert user.sync_default_scope.nil?
  end

  it 'does not sync if sync is not enabled' do
    user = UserWithSimpleScope.new name: "Foo"
    user.stubs(:publish_actions)
    
    user.expects(:publish_actions).never
    user.save!
  end

  class FakeModelWithParent < ActiveRecord::Base
    self.table_name = 'todos'
    sync :all, scope: :my_scope
  end

  it 'can have a scope specified when mixed into the model' do
    # model = FakeModelWithParent.new
    # scope = FakeModel.new
    # model.stubs(:sync_new)
    # model.stubs(:sync_update)
    # model.stubs(:sync_destroy)
    # model.stubs(:my_scope).returns(scope)
    # scope.stubs(:reload).returns(scope)
    # 
    # assert_equal scope, model.sync_default_scope
    # 
    # Sync::Model.enable do
    #   model.expects(:sync_new).with(model, scope: scope)
    #   model.save!
    # 
    #   model.expects(:sync_update).with([model, scope])
    #   model.save!
    # 
    #   model.expects(:sync_destroy).with(model)
    #   model.expects(:sync_update).with(scope)
    #   model.destroy
    # end
  end
end
