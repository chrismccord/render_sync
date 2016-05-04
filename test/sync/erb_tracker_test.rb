require_relative '../test_helper'
require 'rails/all'
require 'active_support/core_ext/array/access'
require 'render_sync/erb_tracker'

describe RenderSync::ERBTracker do
  Template = Struct.new(:source)
  it 'tracks collection partials' do
    dependencies = RenderSync::ERBTracker.call "name", Template.new(<<-TEMPLATE)
      <%= sync partial: 'item', collection: something.things %>
    TEMPLATE

    assert_equal ['sync/things/item'], dependencies
  end

  it 'tracks collection instance variable partials' do
    dependencies = RenderSync::ERBTracker.call "name", Template.new(<<-TEMPLATE)
      <%= sync partial: 'item', collection: @something.things %>
    TEMPLATE

    assert_equal ['sync/things/item'], dependencies
  end

  it 'tracks resource partials' do
    dependencies = RenderSync::ERBTracker.call "name", Template.new(<<-TEMPLATE)
      <%= sync partial: 'item', resource: thing %>
    TEMPLATE

    assert_equal ['sync/things/item'], dependencies
  end

  it 'tracks sync_new partials' do
    dependencies = RenderSync::ERBTracker.call "name", Template.new(<<-TEMPLATE)
      <%= sync_new partial: 'item', resource: thing %>
    TEMPLATE

    assert_equal ['sync/things/item'], dependencies
  end

  it 'tracks multiple sync partials' do
    dependencies = RenderSync::ERBTracker.call "name", Template.new(<<-TEMPLATE)
      <%= sync partial: 'item', resource: thing %>
      <%= sync partial: 'other_item', resource: rock %>
    TEMPLATE

    assert_equal ['sync/things/item', 'sync/rocks/other_item'], dependencies
  end

  it 'tracks resource instance variable partials' do
    dependencies = RenderSync::ERBTracker.call "name", Template.new(<<-TEMPLATE)
      <%= sync partial: 'item', resource: @thing %>
    TEMPLATE

    assert_equal ['sync/things/item'], dependencies
  end

  it 'tracks haml resource partials' do
    dependencies = RenderSync::ERBTracker.call "name", Template.new(<<-TEMPLATE)
      =sync partial: 'item', resource: thing
    TEMPLATE

    assert_equal ['sync/things/item'], dependencies
  end

  it 'tracks regular renders too' do
    dependencies = RenderSync::ERBTracker.call "name", Template.new(<<-TEMPLATE)
      <%= render partial: 'things/item', collection: things %>
    TEMPLATE

    assert_equal ['things/item'], dependencies
  end
end
