require_relative '../test_helper'
require 'rails/all'
require_relative 'abstract_controller'
require_relative '../models/user'

describe RenderSync::Partial do
  include TestHelper

  before do
    @context = ActionController::Base.new
    @partial = RenderSync::Partial.new("show", User.new, nil, @context)
  end

  describe '#self.all' do
    it 'returns an array of all Partials for given model' do
      assert_equal 1, RenderSync::Partial.all(User.new, @context).size
      assert_equal RenderSync::Partial, RenderSync::Partial.all(User.new, @context)[0].class
    end
  end

  describe '#self.find' do
    it 'finds partial given resource and partial name' do
      Dir.stubs(:[]).returns("_show.html.erb")
      assert_equal RenderSync::Partial, RenderSync::Partial.find(User.new, 'show', nil).class
    end

    it 'returns nil if partial does not exist' do
      Dir.stubs(:[]).returns []
      refute RenderSync::Partial.find(User.new, 'not_exist', nil)
    end
  end

  describe '#render_to_string' do
    it 'renders itself as a string' do
      assert_equal "<h1>1<\/h1>", @partial.render_to_string
    end
  end

  describe '#render' do
    it 'renders' do
      # TODO stub out
      assert @partial.respond_to?(:render)
    end
  end

  describe '#sync' do
    it 'sends update to faye for given partial and update action' do
      # TODO stub out
      assert @partial.sync(:update)
    end

    it 'sends update to faye for given partial and destroy action' do
      # TODO stub out
      assert @partial.sync(:destroy)
    end
  end

  describe '#message' do
    it 'returns a Message instance for the partial for the update action' do
      assert_equal RenderSync.client.class::Message, @partial.message(:update).class
    end

     it 'returns a Message instance for the partial for the destroy action' do
      assert_equal RenderSync.client.class::Message, @partial.message(:destroy).class
    end
  end

  describe '#channel_prefix' do
    it 'returns a unique channel prefix for the partial given its name and resource' do
      assert @partial.channel_prefix
    end
  end

  describe 'channel_for_action' do
    it 'returns the channel for the update action' do
      assert @partial.channel_for_action(:update)
    end

    it 'returns the channel for the destroy action' do
      assert @partial.channel_for_action(:destroy)
    end

    it 'always starts with a forward slash to provide Faye valid channel' do
      assert_equal "/", @partial.channel_for_action(:update).first
      assert_equal "/", @partial.channel_for_action(:destroy).first
    end
  end

  describe '#selector_start' do
    it 'returns a string for the selector to mark element beginning' do
      assert @partial.selector_start.present?
    end
  end

  describe '#selector_end' do
    it 'returns a string for the selector to mark element ending' do
      assert @partial.selector_end.present?
    end
  end

  describe 'creator_for_scope' do
    it 'returns a new PartialCreator for given scope' do
      assert_equal RenderSync::PartialCreator, @partial.creator_for_scope(nil).class
      assert @partial, @partial.creator_for_scope(nil).partial
    end
  end
end
