require "test_helper"
require "voice_command/providers/gemini_provider"

class VoiceCommand::Providers::GeminiProviderTest < ActiveSupport::TestCase
  setup do
    @config = VoiceCommand::Configuration.new
    @config.gemini_api_key = "test_key"
    @provider = VoiceCommand::Providers::GeminiProvider.new(@config)
  end

  test "initializes with config" do
    assert_equal @config, @provider.config
  end

  # Note: Full integration tests would require mocking the RubyLLM gem
  # or using VCR/WebMock to record and replay HTTP interactions
end
