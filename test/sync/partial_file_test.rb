require_relative '../test_helper'

describe Sync::PartialFile do
  include TestHelper

  describe '#valid?' do

    it 'returns true for partials beginning with underscore' do
      assert Sync::PartialFile.new("_valid_partial.html.erb").valid?
    end

    it 'returns false for non underscore prefixed files' do
      refute Sync::PartialFile.new("invvalid_partial.html.erb").valid?
      refute Sync::PartialFile.new(".DS_Store").valid?
      refute Sync::PartialFile.new(".gitkeep").valid?
      refute Sync::PartialFile.new("file").valid?
    end
  end

  describe '#basename' do
    it "returns the file's basename" do
      assert_equal "_partial", Sync::PartialFile.new("_partial.html.erb").basename
    end
  end

  describe '#name_without_underscore' do
    it "returns the file's name without a prefixed underscore character" do
      assert_equal "partial", Sync::PartialFile.new("_partial.html.erb").name_without_underscore
    end
  end
end
