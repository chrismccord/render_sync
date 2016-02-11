require 'rails/all'
require_relative '../test_helper'
require_relative 'abstract_controller'
require_relative '../models/user'
require_relative '../models/project'
require_relative '../models/group'
require_relative '../models/todo'

describe RenderSync::Scope do
  include TestHelper

  describe '#initialize' do
    it 'return an RenderSync::Scope instance' do
      assert_kind_of RenderSync::Scope, User.with_group_id(5)
    end

    it 'raises an argument error with an invalid param (float)' do
      assert_raises ArgumentError do 
        User.with_group_id(0.5)
      end
    end

    it 'returns an RenderSync::Scope instance and sets instance variables correctly' do
      scope = User.with_group_id(5)
      assert_kind_of RenderSync::Scope, scope
      assert_equal scope.args, [5]
      assert_equal scope.scope_definition, User.sync_scope_definitions[:with_group_id]
    end
  end
  
  describe '#new_from_model' do
    it 'returns an RenderSync::Scope instance and sets instance variables correctly' do
      scope_definition = User.sync_scope_definitions[:with_group_id]
      user = User.create(group_id: 3)
      scope = RenderSync::Scope.new_from_model(scope_definition, user)
      assert_kind_of RenderSync::Scope, scope
      assert_equal scope.args, [3]
      assert_equal scope.scope_definition, scope_definition
    end
  end

  describe '#relation' do
    it 'returns the ActiveRecord::Relation' do
      scope = User.with_group_id(5)
      assert_kind_of ActiveRecord::Relation, scope.relation
    end
  end
  
  describe '#valid?' do
    it 'returns true for a relation that does not throw an exception' do
      scope = User.with_group_id(5)
      assert_equal true, scope.valid?
    end

    it 'returns false for a relation that throws an exception' do
      scope_definition = User.sync_scope_definitions[:in_group]
      user = User.create(group: nil)
      scope = RenderSync::Scope.new_from_model(scope_definition, user)
      assert_equal false, scope.valid?
    end
  end

  describe '#contains?' do
    it 'returns true if the given record is in the scope' do
      todo = Todo.create(user_id: 2)
      scope = Todo.with_user_id(2)
      assert_equal true, scope.contains?(todo)
    end

    it 'returns false if the given record is not in the scope' do
      todo = Todo.create(user_id: 2)
      scope = Todo.with_user_id(5)
      assert_equal false, scope.contains?(todo)
    end
  end

  describe 'setting up a sync scope in the model' do
    it 'adds a simple scope definition to the model class' do
      class User < ActiveRecord::Base
        sync_scope :without_name, -> { where(name: nil)}
      end
      assert User.sync_scope_definitions[:without_name].present?
    end

    it 'adds a scope definition if lambda names are correct' do
      class User < ActiveRecord::Base
        sync_scope :with_age, ->(age) { where(age: age)}
      end
      assert User.sync_scope_definitions[:with_age].present?
    end

    it 'raises an exception if lambda arg names are invalid' do
      assert_raises ArgumentError do 
        class User < ActiveRecord::Base
          sync_scope :with_max_age, ->(max_age) { where(["age <= ?", max_age])}
        end
      end
      assert User.sync_scope_definitions[:with_max_age].blank?
    end

    it 'raises an exception if sync scope name method with that name is already defined' do
      assert_raises ArgumentError do 
        class User < ActiveRecord::Base
          sync_scope :old, -> { where(["arg > ?", 70])}
          sync_scope :old, -> { where(["arg > ?", 90])}
        end
      end
    end
    
    
  end

end
