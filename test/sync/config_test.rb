require_relative '../test_helper'

describe Sync.config do
  before do
    Sync.load_config(
      File.expand_path("../../fixtures/sync_erb.yml", __FILE__),
      "test"
    )
  end

  describe "#load_config" do
    it "Evaluates ERB from the config file" do
      assert_equal("erb secret", Sync.config[:auth_token])
    end
  end
end