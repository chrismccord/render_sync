require_relative '../test_helper'

describe RenderSync::FayeExtension do
  include TestHelper

  before do
    @server = RenderSync::FayeExtension.new
    @message = {
      "channel" => "/channel",
      "message" => "HTML",
      "ext" => {"auth_token" => "secret"}
    }
    @unauthed_message = {
      "channel" => "/channel",
      "message" => "HTML",
      "ext" => {"auth_token" => "WRONG"} 
    }
    @batched_message = {
      "data" => [{
        "channel" => "/channel",
        "message" => "HTML",
        "ext" => {"auth_token" => "secret"}
      },
      {
        "channel" => "/channel",
        "message" => "HTML",
        "ext" => {"auth_token" => "secret"}
      }]
    }
  end

  describe 'incoming messages' do
    describe 'message authentication' do
      describe 'with valid auth_token' do
        it 'should be valid' do
          assert @server.message_authenticated?(@message)
        end
      end

      describe 'with invalid auth_token' do
        it 'should be invalid' do
          refute @server.message_authenticated?(@unauthed_message)
        end

        it 'should add error to message before callback' do
          assert @server.incoming(@unauthed_message, Proc.new{|msg| msg["error"]})
        end
      end
    end
  end

  describe 'outgoing messages' do
    it 'should strip out message auth_token to prevent auth_token leak' do
      assert_equal nil, @server.outgoing(
        {"ext" => {"auth_token" => "secret"}}, 
        Proc.new{|message| message["ext"]["auth_token"] }
      )
    end
  end

  describe 'batch_incoming' do
    it 'proccesses all batched messages as single message' do
      assert @server.batch_incoming(@batched_message, Proc.new{})
    end
  end

  describe 'single_incoming(message, callback)' do
  end

  describe 'batch_publish?' do
    describe 'with batched messages' do
      it 'should be true' do
        assert @server.batch_publish?({
          'channel' => '/batch_publish'
        })
      end
    end

    describe 'with single message' do
      it 'should be false' do
        refute @server.batch_publish?({
          'channel' => '/some-channel'
        })
      end
    end
  end
end
