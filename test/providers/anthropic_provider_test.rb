require "test_helper"
require "voice_command/providers/anthropic_provider"

class VoiceCommand::Providers::AnthropicProviderTest < ActiveSupport::TestCase
  setup do
    @config = VoiceCommand::Configuration.new
    @config.anthropic_api_key = "test_key"
    @provider = VoiceCommand::Providers::AnthropicProvider.new(@config)
  end

  test "initializes with config" do
    assert_equal @config, @provider.config
  end

  test "process_audio raises error for unsupported audio" do
    error = assert_raises VoiceCommand::ProviderError do
      @provider.process_audio("path/to/audio.mp3", "prompt")
    end

    assert_match /Anthropic does not support direct audio transcription/, error.message
  end

  # Note: Full integration tests for process_text would require mocking the Anthropic API
  # or using VCR/WebMock to record and replay HTTP interactions
end
