require 'rails/all'
require_relative '../test_helper'
require_relative 'abstract_controller'
require_relative '../models/user'
require_relative '../models/project'
require_relative '../models/group'

describe RenderSync::Partial do
  include TestHelper

  before do
    @user = User.create
    @group = Group.create 
    @project = Project.create
  end

  describe '#name' do
    it 'returns the underscored model class name' do
      assert_equal "user", RenderSync::Resource.new(@user).name
    end
  end

  describe '#plural_name' do
    it 'returns the underscored model class name' do
      assert_equal "users", RenderSync::Resource.new(@user).plural_name
    end
  end

  describe '#id' do
    it 'returns the models id' do
      assert_equal 1, RenderSync::Resource.new(@user).id
    end
  end

  describe '#scopes=' do
    before do
      @resource = RenderSync::Resource.new(@user)
    end

    it 'ignores nil' do
      @resource.scopes = nil
      assert_nil @resource.scopes
    end

    it 'converts scalar value to an array' do
      @resource.scopes = :en
      assert_equal [:en], @resource.scopes
    end

  end

  describe '#scopes_path' do
    describe 'a resource without a scope' do
      it 'returns /' do
        resource = RenderSync::Resource.new(@user)
        assert_equal '/', resource.scopes_path.to_s
      end
    end

    describe 'a resource with a simple scope' do
      it 'returns a path prefixed with the scope' do
        resource = RenderSync::Resource.new(@user, :admin)
        assert_equal '/admin', resource.scopes_path.to_s
      end
    end

    describe 'a resource with a parent model as scope' do
      it "returns the parent model's path" do
        resource = RenderSync::Resource.new(@user, @project)
        assert_equal "/projects/#{@project.id}", resource.scopes_path.to_s
      end
    end

    describe 'a resource with mixed scopes' do
      it 'returns a path including all scopes' do
        resource = RenderSync::Resource.new(@user, [:en, :admin, @project])
        assert_equal "/en/admin/projects/#{@project.id}", resource.scopes_path.to_s
      end
    end
  end

  describe '#polymorphic_path' do
    describe 'a resource without a scope' do
      it 'returns the path for the model' do
        assert_equal "/users/1", RenderSync::Resource.new(@user).polymorphic_path.to_s
      end
    end

    describe 'a resource with a simple scope' do
      it 'returns the path for the model, prefixed by the scope' do
        resource = RenderSync::Resource.new(@user, :en) 
        assert_equal "/en/users/1", resource.polymorphic_path.to_s
      end
    end

    describe 'a resource with a parent model as scope' do
      it 'returns the path for the model, prefixed by parent path' do
        child = RenderSync::Resource.new(@user, @project)
        assert_equal "/projects/#{@project.id}/users/1", child.polymorphic_path.to_s
      end
    end

    describe 'a resource with an RenderSync::Scope object as scope' do
      it 'returns the path for the model, prefixed by sync_scope path' do
        child = RenderSync::Resource.new(@user, User.cool)
        assert_equal "/cool/users/1", child.polymorphic_path.to_s
      end
    end

    describe 'a resource with an RenderSync::Scope object with AR-param as scope' do
      it 'returns the path for the model, prefixed by sync_scope path' do
        child = RenderSync::Resource.new(@user, User.in_group(@group))
        assert_equal "/in_group/group/#{@group.id}/users/1", child.polymorphic_path.to_s
      end
    end

    describe 'a resource with an RenderSync::Scope object with Integer-param as scope' do
      it 'returns the path for the model, prefixed by sync_scope path' do
        child = RenderSync::Resource.new(@user, User.with_group_id(@group.id))
        assert_equal "/with_group_id/group_id/#{@group.id}/users/1", child.polymorphic_path.to_s
      end
    end

    describe 'a resource with an RenderSync::Scope object with multiple params as scope' do
      it 'returns the path for the model, prefixed by sync_scope path' do
        child = RenderSync::Resource.new(@user, User.with_min_age_in_group(15, @group.id))
        assert_equal "/with_min_age_in_group/age/15/group_id/#{@group.id}/users/1", child.polymorphic_path.to_s
      end
    end

    describe 'a resource with mixed scopes' do
      it 'returns the path for the model, prefixed by all scopes' do
        child = RenderSync::Resource.new(@user, [:en, :admin, @project, User.cool, User.in_group(@group)])
        assert_equal "/en/admin/projects/#{@project.id}/cool/in_group/group/#{@group.id}/users/1", child.polymorphic_path.to_s
      end
    end
  end

  describe '#model_path' do
    it 'returns the raw path of the model without any scopes' do
      child = RenderSync::Resource.new(@user, @project)
      assert_equal "/users/1", child.model_path.to_s
    end
  end

  describe '#polymorphic_new_path' do
    describe 'a resource without a scope' do
      it 'returns the path for the model' do
        assert_equal "/users/new", RenderSync::Resource.new(@user).polymorphic_new_path.to_s
      end
    end

    describe 'a resource with a simple scope' do
      it 'returns the path for the model, prefixed by the scope' do
        resource = RenderSync::Resource.new(@user, :en)
        assert_equal "/en/users/new", resource.polymorphic_new_path.to_s
      end
    end

    describe 'a resource with a parent model as scope' do
      it 'returns the path for the model, prefixed by parent path' do
        child = RenderSync::Resource.new(@user, @project)
        assert_equal "/projects/#{@project.id}/users/new", child.polymorphic_new_path.to_s
      end
    end

    describe 'a resource with a RenderSync::Scope object as scope' do
      it 'returns the path for the model, prefixed by parent path' do
        child = RenderSync::Resource.new(@user, User.cool)
        assert_equal "/cool/users/new", child.polymorphic_new_path.to_s
      end
    end

    describe 'a resource with mixed scopes' do
      it 'returns the path for the model, prefixed by all scopes' do
        child = RenderSync::Resource.new(@user, [:en, :admin, @project, User.cool, User.in_group(@group)])
        assert_equal "/en/admin/projects/#{@project.id}/cool/in_group/group/#{@group.id}/users/new", child.polymorphic_new_path.to_s
      end
    end
  end
end
