require "test_helper"

class VoiceCommand::ResultTest < ActiveSupport::TestCase
  test "creates successful result" do
    result = VoiceCommand::Result.success(response: "Task completed")

    assert result.success?
    assert_not result.failure?
    assert_equal "Task completed", result.response
    assert_nil result.error
  end

  test "creates failure result" do
    result = VoiceCommand::Result.failure(error: "Something went wrong")

    assert result.failure?
    assert_not result.success?
    assert_equal "Something went wrong", result.error
    assert_nil result.response
  end

  test "can create result with new" do
    result = VoiceCommand::Result.new(success: true, response: "Done")

    assert result.success?
    assert_equal "Done", result.response
  end
end
