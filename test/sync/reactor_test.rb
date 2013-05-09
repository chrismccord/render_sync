require_relative '../test_helper'
require 'mocha/setup'


describe Sync::Reactor do
  include TestHelper
  
  describe '#start' do
    
    before do
      Sync.reactor.stop
      sleep 0.1
    end

    it 'starts when not using thin' do
      Sync.reactor.stubs(:using_thin?).returns false
      refute Sync.reactor.running?
      Sync.reactor.start
      sleep 0.1
      assert Sync.reactor.running?
    end

    it 'does not start when using thin' do
      Sync.reactor.stubs(:using_thin?).returns true
      refute Sync.reactor.running?
      Sync.reactor.start
      sleep 0.1
      refute Sync.reactor.running?
    end
  end
end
