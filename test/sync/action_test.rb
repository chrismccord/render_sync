require_relative '../test_helper'
require 'mocha/setup'
require 'rails/all'

describe RenderSync::Action do
  include TestHelper

  describe '#initialize' do
    it 'sets instance variables on initialize without scopes' do
      action = RenderSync::Action.new("record", :new)
      assert_equal "record", action.record
      assert_equal :new, action.name
      assert_equal [], action.scope
    end

    it 'sets instance variables on initialize with scope' do
      action = RenderSync::Action.new("record", :new, scope: "scope")
      assert_equal ["scope"], action.scope
    end

    it 'sets instance variables on initialize with default_scope' do
      action = RenderSync::Action.new("record", :new, default_scope: "scope")
      assert_equal ["scope"], action.scope
    end

    it 'sets instance variables on initialize with scope and default_scope' do
      action = RenderSync::Action.new("record", :new, scope: "scope", default_scope: "default")
      assert_equal ["default", "scope"], action.scope
    end

    it 'sets instance variables on initialize with default_scope' do
      user = User.create!
      scope = User.cool
      action = RenderSync::Action.new(user, :new, scope: scope, default_scope: :group)
      assert_equal [:group, scope], action.scope
    end


    it 'sets instance variables on initialize with nested scopes' do
      action = RenderSync::Action.new("record", :new, scope: ["nested", "scopes"], default_scope: ["my", "cool"])
      assert_equal [["my", "cool"], ["nested", "scopes"]], action.scope
    end
  end
  
  describe "#perform" do
    
    it 'calls different actions without scope' do
      record = User.new name: "Foo"
      
      action = RenderSync::Action.new(record, :new)
      action.expects(:sync_new).with(record, scope: [])
      action.perform

      action = RenderSync::Action.new(record, :update)
      action.expects(:sync_update).with(record, scope: [])
      action.perform

      action = RenderSync::Action.new(record, :destroy)
      action.expects(:sync_destroy).with(record, scope: [])
      action.perform
    end

    it 'calls different actions with scope' do
      record = User.new name: "Foo"
      
      action = RenderSync::Action.new(record, :new, scope: "scope", default_scope: "default")
      action.expects(:sync_new).with(record, scope: ["default", "scope"])
      action.perform

      action = RenderSync::Action.new(record, :update, scope: "scope", default_scope: "default")
      action.expects(:sync_update).with(record, scope: ["default", "scope"])
      action.perform

      action = RenderSync::Action.new(record, :destroy, scope: "scope", default_scope: "default")
      action.expects(:sync_destroy).with(record, scope: ["default", "scope"])
      action.perform
    end

    
  end

end
