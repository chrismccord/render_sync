require_relative '../test_helper'
require 'mocha/setup'
require 'rails/all'

setup_database

describe Sync::Model do

  it 'is disabled by default' do
    refute Sync::Model.enabled?
  end

  it 'can be enabled and disabled' do
    Sync::Model.enable!
    assert Sync::Model.enabled?

    Sync::Model.disable!
    refute Sync::Model.enabled?
  end

  it 'can be given a block to have things enabled in' do
    Sync::Model.enable do
      assert Sync::Model.enabled?
    end

    refute Sync::Model.enabled?
  end

  class FakeModel < ActiveRecord::Base
    self.table_name = 'todos'

    sync :all
  end

  let(:model) { FakeModel.new name: "Foo" }

  it 'can be mixed into a model to allow sync' do
    model.stubs(:sync_new)
    model.stubs(:sync_update)
    model.stubs(:sync_destroy)

    Sync::Model.enable do
      model.expects(:sync_new).with(model, scope: nil)
      model.save!

      model.expects(:sync_update).with(model)
      model.save!

      model.expects(:sync_destroy).with(model)
      model.destroy
    end
  end

  it 'does not have a sync scope if it is not specified' do
    assert model.sync_scope.nil?
  end

  it 'does not sync if sync is not enabled' do
    model = FakeModel.new name: "Foo"
    model.stubs(:sync_new)

    model.expects(:sync_new).with(model).never
    model.save!
  end

  class FakeModelWithParent < ActiveRecord::Base
    self.table_name = 'todos'
    sync :all, scope: :my_scope
  end

  it 'can have a scope specified when mixed into the model' do
    model = FakeModelWithParent.new
    scope = FakeModel.new
    model.stubs(:sync_new)
    model.stubs(:sync_update)
    model.stubs(:sync_destroy)
    model.stubs(:my_scope).returns(scope)
    scope.stubs(:reload).returns(scope)

    assert_equal scope, model.sync_scope

    Sync::Model.enable do
      model.expects(:sync_new).with(model, scope: scope)
      model.save!

      model.expects(:sync_update).with([model, scope])
      model.save!

      model.expects(:sync_destroy).with(model)
      model.expects(:sync_update).with(scope)
      model.destroy
    end
  end
end
