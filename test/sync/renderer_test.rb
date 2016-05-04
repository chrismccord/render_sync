require_relative '../test_helper'
require_relative '../models/user'

describe RenderSync::Renderer do
  include TestHelper

  class ApplicationController < ActionController::Base
  end

  let(:renderer){ RenderSync::Renderer.new }

  describe '#render_to_string' do
    it 'renders partial as string' do
      assert_equal "<h1>1<\/h1>", renderer.render_to_string(
        partial: 'sync/users/show', locals: { user: User.new }
      )
    end
  end
end
