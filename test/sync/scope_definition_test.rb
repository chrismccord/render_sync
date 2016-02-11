require_relative '../test_helper'
require_relative '../models/user'

describe RenderSync::ScopeDefinition do
  include TestHelper

  describe '#ensure_valid_params!' do
    it 'raises an argument error with one invalid argument' do
      assert_raises ArgumentError do 
        # attribute, associtation or instance method 'project' not present in user instance
        RenderSync::ScopeDefinition.ensure_valid_params!(User, ->(project) { User.all })
      end
    end
    
    it 'raises an argument error with a valid and an invalid argument' do
      assert_raises ArgumentError do 
        # attribute, associtation or instance method 'project' not present in user instance
        # name is a column on user record
        RenderSync::ScopeDefinition.ensure_valid_params!(User, ->(name, project) { User.all })
      end
    end

    it 'returns true with no arguments' do
      assert_equal true, RenderSync::ScopeDefinition.ensure_valid_params!(User, -> { User.all })
    end
        
    it 'returns true with one valid argument' do
      # group is an association on the user record
      assert_equal true, RenderSync::ScopeDefinition.ensure_valid_params!(User, ->(group) { User.all })
    end

    it 'returns true with multiple valid argument' do
      # group is an association on the user record
      # name is a column on user record
      assert_equal true, RenderSync::ScopeDefinition.ensure_valid_params!(User, ->(group, name) { User.all })
    end

  end
end
