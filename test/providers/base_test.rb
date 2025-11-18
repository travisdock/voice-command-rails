require "test_helper"
require "voice_command/providers/base"

class VoiceCommand::Providers::BaseTest < ActiveSupport::TestCase
  setup do
    @config = VoiceCommand::Configuration.new
  end

  test "initializes with config" do
    provider = VoiceCommand::Providers::Base.new(@config)
    assert_equal @config, provider.config
  end

  test "process_audio raises NotImplementedError" do
    provider = VoiceCommand::Providers::Base.new(@config)

    error = assert_raises NotImplementedError do
      provider.process_audio("path/to/audio.mp3", "prompt")
    end

    assert_match /Subclasses must implement #process_audio/, error.message
  end
end
