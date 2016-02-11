require_relative '../test_helper'
require_relative '../models/user'
require 'mocha/setup'

describe RenderSync::RefetchModel do
  include TestHelper

  describe '#find_by_class_name_and_id' do
    it 'finds record by model name and id' do
      User.expects(:find).once.returns(User.new)
      RenderSync::RefetchModel.stubs(:supported_classes).returns ["User"]
      assert RenderSync::RefetchModel.find_by_class_name_and_id("user", 1).is_a? User
    end

    it 'Returns nil if class name is not sync model' do
      Object.expects(:find).never
      refute RenderSync::RefetchModel.find_by_class_name_and_id("object", 1)
    end

    it "Returns nil if record is not found for id" do
      User.expects(:find).once.raises(StandardError.new("Record not found"))
      RenderSync::RefetchModel.stubs(:supported_classes).returns ["User"]
      refute RenderSync::RefetchModel.find_by_class_name_and_id("user", 1)
    end
  end
end
