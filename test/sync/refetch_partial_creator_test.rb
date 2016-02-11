require_relative '../test_helper'

describe RenderSync::RefetchPartialCreator do
  include TestHelper

  before do
    @context = ActionController::Base.new
    @partial_creator = RenderSync::RefetchPartialCreator.new("show", User.new, scope = nil, @context)
  end

  describe '#message' do
    it 'returns a Message instance for the partial for the update action' do
      assert_equal RenderSync.client.class::Message, @partial_creator.message.class
    end
  end
end
