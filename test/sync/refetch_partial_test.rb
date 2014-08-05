require_relative '../test_helper'
require 'rails/all'
require_relative 'abstract_controller'
require_relative '../models/user'

describe Sync::RefetchPartial do
  include TestHelper

  before do
    @context = ActionController::Base.new
    @partial = Sync::RefetchPartial.new("show", User.new, nil, @context)
  end
 
  describe '#self.all' do
    it 'returns an array of all Partials for given model' do
      assert_equal 1, Sync::RefetchPartial.all(User.new, @context).size
      assert_equal Sync::RefetchPartial, Sync::RefetchPartial.all(User.new, @context)[0].class
    end
  end

  describe '#self.find' do
    it 'finds partial given resource and partial name' do
      assert_equal Sync::RefetchPartial, Sync::RefetchPartial.find(User.new, 'show', @context).class
    end

    it 'returns nil if partial does not exist' do
      refute Sync::RefetchPartial.find(User.new, 'not_exist', nil)
    end
  end

  describe '#self.find_by_authorized_resource' do

    it 'returns partial when given auth token for resource and template' do
      assert_equal Sync::RefetchPartial, Sync::RefetchPartial.find_by_authorized_resource(
        @partial.resource.model,
        @partial.name,
        nil, 
        @partial.auth_token
      ).class
    end

    it 'returns nil when given invalid auth token for resource and template' do
      refute Sync::RefetchPartial.find_by_authorized_resource(
        @partial.resource.model,
        @partial.name,
        nil, 
        "invalid auth token"
      )
    end
  end

  describe '#render_to_string' do
    it 'renders itself as a string from the refetch directory' do
      assert_equal "<h1>Refetch 1<\/h1>", @partial.render_to_string
    end
  end

  describe '#message' do
    it 'returns a Message instance for the partial for the update action' do
      assert_equal Sync.client.class::Message, @partial.message(:update).class
    end

     it 'returns a Message instance for the partial for the destroy action' do
      assert_equal Sync.client.class::Message, @partial.message(:destroy).class
    end
  end

  describe 'creator_for_scope' do
    it 'returns a new PartialCreator for given scope' do
      assert_equal Sync::RefetchPartialCreator, @partial.creator_for_scope(nil).class
      assert @partial, @partial.creator_for_scope(nil).partial
    end
  end
end
