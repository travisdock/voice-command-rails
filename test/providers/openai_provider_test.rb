require "test_helper"
require "voice_command/providers/openai_provider"

class VoiceCommand::Providers::OpenAIProviderTest < ActiveSupport::TestCase
  setup do
    @config = VoiceCommand::Configuration.new
    @config.openai_api_key = "test_key"
    @provider = VoiceCommand::Providers::OpenAIProvider.new(@config)
  end

  test "initializes with config" do
    assert_equal @config, @provider.config
  end

  test "raises ProviderError when OpenAI gem is not available" do
    # This test would need to mock the require to fail
    # For now, we'll skip actual API call tests as they require real API keys
    skip "Requires mocking OpenAI gem"
  end

  # Note: Full integration tests would require mocking the OpenAI API
  # or using VCR/WebMock to record and replay HTTP interactions
end
