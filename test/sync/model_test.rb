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

  describe 'syncing' do
    it 'publishes new record to main channel' do
      Sync::Model.enable do
        user = UserWithoutScopes.new
        user.save!
        assert user.persisted?
        assert_equal 1, user.sync_actions.size
        assert_equal [:new], user.sync_actions.map(&:name).uniq

        user.update_attributes!(name: "Stefan")
        assert user.persisted?
        assert_equal 1, user.sync_actions.size
        assert_equal [:update], user.sync_actions.map(&:name).uniq
      end
    end

    it 'publishes new record with scopes to main channel and scope channels' do
      Sync::Model.enable do
        user = UserWithOneScope.new
        user.save!
        assert_equal 2, user.sync_actions.size
        assert_equal [:new], user.sync_actions.map(&:name).uniq
      end
    end
  end

  it 'does not have a sync default scope if it is not specified' do
    user = User.new name: "Foo"
    assert user.sync_default_scope.nil?
  end

  it 'does not sync if sync is not enabled' do
    user = UserWithOneScope.new name: "Foo"
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
