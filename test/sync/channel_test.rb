require_relative '../test_helper'

describe Sync::Channel do
  include TestHelper

  describe '#signature' do
    before do
      @channel = Sync::Channel.new("testing")
    end

    it "Creates uniqe HMAC signature" do
      assert_equal 40, @channel.signature.length
    end
  end
end
