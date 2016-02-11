require_relative '../test_helper'
require 'mocha/setup'


describe RenderSync::Reactor do
  include TestHelper
  
  describe '#perform' do
    it 'starts EventMachine thread and runs block' do
      refute RenderSync.reactor.running?
      ran_block = false
      RenderSync.reactor.perform { ran_block = true}
      assert RenderSync.reactor.running?
      sleep 0.1
      assert ran_block
    end
  end
end
