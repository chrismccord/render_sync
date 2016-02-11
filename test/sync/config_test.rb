require_relative '../test_helper'

describe RenderSync.config do
  before do
    RenderSync.load_config(
      File.expand_path("../../fixtures/sync_erb.yml", __FILE__),
      "test"
    )
  end

  describe "#load_config" do
    it "Evaluates ERB from the config file" do
      assert_equal("erb secret", RenderSync.config[:auth_token])
    end

    it "raises an exception if auth_token is missing" do
      assert_raises ArgumentError do
        RenderSync.load_config(
          File.expand_path("../../fixtures/sync_auth_token_missing.yml", __FILE__),
          "test"
        )
      end
    end
  end
end
