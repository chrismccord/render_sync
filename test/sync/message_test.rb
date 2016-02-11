require_relative '../test_helper'
require 'mocha/setup'


describe "Faye" do
  include TestHelperFaye

  before do
    @message = RenderSync.client.build_message("/my-channel", html: "<p>Some Data</p>")
  end

  describe "normalize_channel" do
    it 'converts channel to faye server friendly format with leading forward-slash' do
      assert_equal "/", RenderSync.client.normalize_channel("alfjalkjfkfjaslkfj2342424")[0]
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

  describe "asynchronous publishing" do
    include EM::MiniTest::Spec

    before do 
      RenderSync.stubs(:async?).returns true
    end
  
    describe "batched message publishing" do
      before do
        @messages = 10.times.collect{|i| RenderSync.client.build_message("/ch#{i}", {html: ""})}
      end

      it 'should publish array of messages with single post to faye' do
        EM.expects(:next_tick).once.returns true
        assert RenderSync.client.batch_publish(@messages)
      end
    end

    describe '#publish' do
      it 'Publishes a message to Faye' do
        RenderSync.reactor.expects(:perform).once
        @message.publish
      end
    end
  end

  describe "synchronous publishing" do
    before do 
      Net::HTTP.stubs(:post_form).returns true
      RenderSync.stubs(:async?).returns false
    end

    describe "batched message publishing" do
      before do
        @messages = 10.times.collect{|i| RenderSync.client.build_message("/ch#{i}", {html: ""})}
      end

      it 'should publish array of messages with single post to faye' do
        assert RenderSync.client.batch_publish(@messages)
      end
    end
    describe '#publish' do
      it 'Publishes a message to Faye' do
        assert @message.publish
      end
    end
  end
end





describe "Pusher" do
  include TestHelperPusher

  before do
    @message = RenderSync.client.build_message("/my-channel", html: "<p>Some Data</p>")
  end

  describe "normalize_channel" do
    it 'converts channel to pusher server friendly format without leading forward-slash' do
      refute RenderSync.client.normalize_channel("alfjalkjfkfjaslkfj2342424")[0] == "/"
    end
  end

  describe '#to_json' do
    it "Converts message to json for Faye publish" do
      assert @message.to_json
    end
  end

  describe "asynchronous publishing" do
    include EM::MiniTest::Spec

    before do 
      RenderSync.stubs(:async?).returns true
    end
  
    describe "batched message publishing" do
      before do
        @messages = 10.times.collect{|i| RenderSync.client.build_message("/ch#{i}", {html: ""})}
      end

      it 'should publish array of messages with single post to faye' do
        assert RenderSync.client.batch_publish(@messages)
      end
    end

    describe '#publish' do
      it 'Publishes a message to Pusher' do
        RenderSync.reactor.expects(:perform).once
        @message.publish
      end
    end
  end

  describe "synchronous publishing" do
    before do 
      Pusher.stubs(:trigger).returns(true)
      RenderSync.stubs(:async?).returns false
    end

    describe "batched message publishing" do
      before do
        @messages = 10.times.collect{|i| RenderSync.client.build_message("/ch#{i}", {html: ""})}
      end

      it 'should publish array of messages with single post to faye' do
        assert RenderSync.client.batch_publish(@messages)
      end
    end
    describe '#publish' do
      it 'Publishes a message to Pusher' do
        assert @message.publish
      end
    end
  end
end

