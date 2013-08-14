require 'rails/all'
require_relative '../test_helper'
require_relative 'abstract_controller'
require_relative 'user'
require_relative 'project'

describe Sync::Partial do
  include TestHelper

  before do
    @user = User.new
    @project = Project.new
  end

  describe '#name' do
    it 'returns the underscored model class name' do
      assert_equal "user", Sync::Resource.new(@user).name
    end
  end

  describe '#plural_name' do
    it 'returns the underscored model class name' do
      assert_equal "users", Sync::Resource.new(@user).plural_name
    end
  end

  describe '#id' do
    it 'returns the models id' do
      assert_equal 1, Sync::Resource.new(@user).id
    end
  end

  describe '#scopes=' do
    before do
      @resource = Sync::Resource.new(@user)
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
        resource = Sync::Resource.new(@user)
        assert_equal '/', resource.scopes_path.to_s
      end
    end

    describe 'a resource with a simple scope' do
      it 'returns a path prefixed with the scope' do
        resource = Sync::Resource.new(@user, :admin)
        assert_equal '/admin', resource.scopes_path.to_s
      end
    end

    describe 'a resource with a parent model as scope' do
      it "returns the parent model's path" do
        resource = Sync::Resource.new(@user, @project)
        assert_equal '/projects/1', resource.scopes_path.to_s
      end
    end

    describe 'a resource with mixed scopes' do
      it 'returns a path including all scopes' do
        resource = Sync::Resource.new(@user, [:en, :admin, @project])
        assert_equal '/en/admin/projects/1', resource.scopes_path.to_s
      end
    end
  end

  describe '#polymorphic_path' do
    describe 'a resource without a scope' do
      it 'returns the path for the model' do
        assert_equal "/users/1", Sync::Resource.new(@user).polymorphic_path.to_s
      end
    end

    describe 'a resource with a simple scope' do
      it 'returns the path for the model, prefixed by the scope' do
        resource = Sync::Resource.new(@user, :en) 
        assert_equal "/en/users/1", resource.polymorphic_path.to_s
      end
    end

    describe 'a resource with a parent model as scope' do
      it 'returns the path for the model, prefixed by parent path' do
        child = Sync::Resource.new(@user, @project)
        assert_equal "/projects/1/users/1", child.polymorphic_path.to_s
      end
    end

    describe 'a resource with mixed scopes' do
      it 'returns the path for the model, prefixed by all scopes' do
        child = Sync::Resource.new(@user, [:en, :admin, @project])
        assert_equal "/en/admin/projects/1/users/1", child.polymorphic_path.to_s
      end
    end
  end

  describe '#polymorphic_new_path' do
    describe 'a resource without a scope' do
      it 'returns the path for the model' do
        assert_equal "/users/new", Sync::Resource.new(@user).polymorphic_new_path.to_s
      end
    end

    describe 'a resource with a simple scope' do
      it 'returns the path for the model, prefixed by the scope' do
        resource = Sync::Resource.new(@user, :en)
        assert_equal "/en/users/new", resource.polymorphic_new_path.to_s
      end
    end

    describe 'a resource with a parent model as scope' do
      it 'returns the path for the model, prefixed by parent path' do
        child = Sync::Resource.new(@user, @project)
        assert_equal "/projects/1/users/new", child.polymorphic_new_path.to_s
      end
    end

    describe 'a resource with mixed scopes' do
      it 'returns the path for the model, prefixed by all scopes' do
        child = Sync::Resource.new(@user, [:en, :admin, @project])
        assert_equal "/en/admin/projects/1/users/new", child.polymorphic_new_path.to_s
      end
    end
  end
end
