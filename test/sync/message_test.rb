require_relative '../test_helper'

describe "Message" do
  include TestHelper

  class NetHttpStub
    def self.post_form(*args)
      true
    end
  end

  before do
    @message = Sync.client.build_message("/my-channel", html: "<p>Some Data</p>")
  end

  describe "batched message publishing" do
    before do
      @messages = 10.times.collect{|i| Sync.client.build_message("/ch#{i}", {html: ""})}
    end

    it 'should publish array of messages with single post to faye' do
      assert Sync.client.batch_publish(@messages, NetHttpStub)
    end
  end

  describe '#to_hash' do
    before do
      @message_hash = @message.to_hash
    end

    it "Converts message to hash for Faye publish" do
      assert @message_hash.keys.include?(:channel)
      assert @message_hash.keys.include?(:data)
      assert @message_hash.keys.include?(:ext)
    end

    it "Includes auth_token for Faye password security" do
      assert @message_hash[:ext][:auth_token]
    end
  end

  describe '#to_json' do
    it "Converts message to json for Faye publish" do
      assert @message.to_json
    end
  end

  describe '#publish' do
    it 'Publishes a message to Faye' do
      assert @message.publish(NetHttpStub)
    end
  end
end
