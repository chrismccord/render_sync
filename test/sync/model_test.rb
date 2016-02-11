require_relative '../test_helper'
require 'mocha/setup'
require 'rails/all'

setup_database

describe RenderSync::Model do

  it 'can is disabled by default' do
    refute RenderSync::Model.enabled?
  end

  it 'can be enabled and disabled' do
    RenderSync::Model.enable!
    assert RenderSync::Model.enabled?

    RenderSync::Model.disable!
    refute RenderSync::Model.enabled?
  end

  it 'can be given a block to have things enabled in' do
    RenderSync::Model.enable do
      assert RenderSync::Model.enabled?
    end

    refute RenderSync::Model.enabled?
  end

  describe 'syncing of model changes to all listening channels' do
    it 'publishes record (create/update/destroy) to main new channel' do
      RenderSync::Model.enable do
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
      RenderSync::Model.enable do

        # Create
        group = Group.create!
        user = UserWithDefaultScope.new(group: group)
        user.save!

        assert user.persisted?
        assert_equal 1, user.sync_actions.size

        assert_equal :new, user.sync_actions[0].name
        assert_equal "/groups/#{group.id}/user_with_default_scopes/#{user.id}", user.sync_actions[0].test_path

        # Update
        user.update_attributes!(name: "Foo")

        assert user.persisted?
        assert_equal 1, user.sync_actions.size

        assert_equal :update, user.sync_actions[0].name
        assert_equal "/user_with_default_scopes/#{user.id}", user.sync_actions[0].test_path

        # Destroy
        user.destroy

        assert user.destroyed?
        assert_equal 1, user.sync_actions.size

        assert_equal :destroy, user.sync_actions[0].name
        assert_equal "/groups/#{group.id}/user_with_default_scopes/#{user.id}", user.sync_actions[0].test_path

      end
    end

    it 'publishes record with simple named sync scope' do
      RenderSync::Model.enable do

        # Create user not in scope 'old' (age > 90)
        user = UserWithSimpleScope.create!(age: 85)

        assert_equal 1, user.sync_actions.size

        assert_equal :new, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        # Create user in scope 'old' (age >= 90)
        user = UserWithSimpleScope.new(age: 95)
        user.save!
        assert_equal 2, user.sync_actions.size

        assert_equal :new, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :new, user.sync_actions[1].name
        assert_equal "/old/user_with_simple_scopes/#{user.id}", user.sync_actions[1].test_path

        # Update of independent attribute name (user still in scope 'old')
        user.update_attributes!(name: "Foo")
        assert !user.changed?
        assert_equal 1, user.sync_actions.size

        assert_equal :update, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        # Update of dependent attribute age, so that the user no longer falls into scope 'old'
        # and has to be destroyed on the scoped channel
        user.update_attributes!(age: 80)
        assert !user.changed?
        assert_equal 2, user.sync_actions.size

        assert_equal :update, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :destroy, user.sync_actions[1].name
        assert_equal "/old/user_with_simple_scopes/#{user.id}", user.sync_actions[1].test_path

        # Update of dependent attribute age, so that the record will fall into scope 'old'
        # and has to be published as new on that scoped channel
        user.update_attributes(age: 100)

        assert !user.changed?
        assert_equal 2, user.sync_actions.size

        assert_equal :update, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :new, user.sync_actions[1].name
        assert_equal "/old/user_with_simple_scopes/#{user.id}", user.sync_actions[1].test_path

        # Destroy user currently in scoped by 'old'
        user.destroy

        assert user.destroyed?
        assert_equal 2, user.sync_actions.size

        assert_equal :destroy, user.sync_actions[0].name
        assert_equal "/user_with_simple_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :destroy, user.sync_actions[1].name
        assert_equal "/old/user_with_simple_scopes/#{user.id}", user.sync_actions[1].test_path

      end
    end

    it 'publishes record with a named sync scope that takes arguments' do
      RenderSync::Model.enable do

        # Create user not in scope 'in_group'
        group1 = Group.create
        group2 = Group.create
        user = UserWithAdvancedScope.create!

        assert user.persisted?
        assert_equal 1, user.sync_actions.size

        assert_equal :new, user.sync_actions[0].name
        assert_equal "/user_with_advanced_scopes/#{user.id}", user.sync_actions[0].test_path

        # Create user in scope 'in_group'
        user = UserWithAdvancedScope.create!(group: group1)

        assert user.persisted?
        assert_equal 2, user.sync_actions.size

        assert_equal :new, user.sync_actions[0].name
        assert_equal "/user_with_advanced_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :new, user.sync_actions[1].name
        assert_equal "/in_group/group/#{group1.id}/user_with_advanced_scopes/#{user.id}", user.sync_actions[1].test_path

        # Change group
        user.update_attributes(group: group2)

        assert user.persisted?
        assert_equal 3, user.sync_actions.size

        assert_equal :update, user.sync_actions[0].name
        assert_equal "/user_with_advanced_scopes/#{user.id}", user.sync_actions[0].test_path

        assert_equal :destroy, user.sync_actions[1].name
        assert_equal "/in_group/group/#{group1.id}/user_with_advanced_scopes/#{user.id}", user.sync_actions[1].test_path

        assert_equal :new, user.sync_actions[2].name
        assert_equal "/in_group/group/#{group2.id}/user_with_advanced_scopes/#{user.id}", user.sync_actions[2].test_path

      end
    end

  end

  describe "touching associated records explicitly" do
    it 'unsyncd user touches single association if configured' do
      RenderSync::Model.enable do
        group1 = Group.create
        group2 = Group.create
        user = UserJustTouchingGroup.create!(group: group1)

        assert user.persisted?
        assert_equal 1, user.sync_actions.size

        assert_equal :update, user.sync_actions[0].name
        assert_equal "/groups/#{group1.id}", user.sync_actions[0].test_path

        user.group = group2
        user.save!

        assert !user.changed?
        assert_equal 2, user.sync_actions.size

        assert_equal :update, user.sync_actions[0].name
        assert_equal "/groups/#{group2.id}", user.sync_actions[0].test_path

        assert_equal :update, user.sync_actions[1].name
        assert_equal "/groups/#{group1.id}", user.sync_actions[1].test_path

        user.group = nil
        user.save!

        assert !user.changed?
        assert_equal 1, user.sync_actions.size

        assert_equal :update, user.sync_actions[0].name
        assert_equal "/groups/#{group2.id}", user.sync_actions[0].test_path
      end
    end

    it 'syncd user touches single association if configured' do
      RenderSync::Model.enable do
        group1 = Group.create
        group2 = Group.create
        user = UserTouchingGroup.create!(group: group1)

        assert user.persisted?
        assert_equal 2, user.sync_actions.size

        assert_equal :update, user.sync_actions[1].name
        assert_equal "/groups/#{group1.id}", user.sync_actions[1].test_path

        user.group = group2
        user.save!

        assert !user.changed?
        assert_equal 3, user.sync_actions.size

        assert_equal :update, user.sync_actions[1].name
        assert_equal "/groups/#{group2.id}", user.sync_actions[1].test_path

        assert_equal :update, user.sync_actions[2].name
        assert_equal "/groups/#{group1.id}", user.sync_actions[2].test_path

        user.group = nil
        user.save!

        assert !user.changed?
        assert_equal 2, user.sync_actions.size

        assert_equal :update, user.sync_actions[1].name
        assert_equal "/groups/#{group2.id}", user.sync_actions[1].test_path
      end
    end

    it 'touches multiple associations if configured' do
      RenderSync::Model.enable do
        group = Group.create
        project = Project.create
        user = UserTouchingGroupAndProject.create!(group: group, project: project)

        assert user.persisted?
        assert_equal 3, user.sync_actions.size

        assert_equal :update, user.sync_actions[1].name
        assert_equal "/groups/#{group.id}", user.sync_actions[1].test_path

        assert_equal :update, user.sync_actions[2].name
        assert_equal "/projects/#{project.id}", user.sync_actions[2].test_path

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

end
