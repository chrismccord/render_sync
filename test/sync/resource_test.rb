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

  describe '#channel' do
    it 'returns nil when no channel is given' do
      refute Sync::Resource.new(@user).channel
    end

    it 'sets the channel to the passed string' do
      assert_equal "admin", Sync::Resource.new(@user, "admin").channel
    end

    it 'sets the channel as the joined array of symbols' do
      assert_equal "admin/restricted", Sync::Resource.new(@user, [:admin, :restricted]).channel
    end

    it 'sets the channel as the joined array of strings' do
      assert_equal "admin/restricted", Sync::Resource.new(@user, ["admin", "restricted"]).channel
    end
  end

  describe 'parent' do
    it 'defaults to NullResource if no parent is given' do
      assert_equal Sync::NullResource, Sync::Resource.new(@user).parent.class
    end

    it 'sets the parent to given resource' do
      resource = Sync::Resource.new(@user)
      parent = Sync::Resource.new(@user)
      resource.parent = parent
      assert_equal parent, resource.parent
    end
  end

  describe '#polymorphic_path' do
    it 'returns the path for the model' do
      assert_equal "/users/1", Sync::Resource.new(@user).polymorphic_path.to_s
    end

    it 'returns the path for the model, prefixed by parent path' do
      child = Sync::Resource.new(@user)
      child.parent = Sync::Resource.new(@project)
      assert_equal "/projects/1/users/1", child.polymorphic_path.to_s
    end

    it 'returns the path for the model, prefixed by parent path and channel' do
      child = Sync::Resource.new(@user)
      child.parent = Sync::Resource.new(@project, :admin)
      assert_equal "/admin/projects/1/users/1", child.polymorphic_path.to_s
    end
  end

  describe '#polymorphic_new_path' do
    it 'returns the path for the model' do
      assert_equal "/users/new", Sync::Resource.new(@user).polymorphic_new_path.to_s
    end

    it 'returns the path for the model, prefixed by parent path' do
      child = Sync::Resource.new(@user)
      child.parent = Sync::Resource.new(@project)
      assert_equal "/projects/1/users/new", child.polymorphic_new_path.to_s
    end

    it 'returns the path for the model, prefixed by parent path and channel' do
      child = Sync::Resource.new(@user)
      child.parent = Sync::Resource.new(@project, :admin)
      assert_equal "/admin/projects/1/users/new", child.polymorphic_new_path.to_s
    end
  end
end
