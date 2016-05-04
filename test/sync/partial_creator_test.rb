require_relative '../test_helper'

describe RenderSync::PartialCreator do
  include TestHelper

  before do
    @context = ActionController::Base.new
    @partial_creator = RenderSync::PartialCreator.new("show", User.new, scope = nil, @context)
  end

  describe '#channel' do
    it 'always starts with a forward slash to provide Faye valid channel' do
      assert_equal "/", @partial_creator.channel.first
    end
  end

  describe '#selector' do
    it 'returns a String selector where partials will be appended in DOM' do
      assert @partial_creator.selector.length > 0
    end
  end

  describe '#sync_new' do
    it 'publishes a new message to faye to append new partials to DOM' do
      # TODO: Stub Message
      assert @partial_creator.sync_new
    end
  end

  describe '#message' do
    it 'returns a Message instance for the partial for the update action' do
      assert_equal RenderSync.client.class::Message, @partial_creator.message.class
    end
  end
end
