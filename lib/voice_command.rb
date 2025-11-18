require "ruby_llm"
require "voice_command/version"
require "voice_command/errors"
require "voice_command/configuration"
require "voice_command/audio_validator"
require "voice_command/processor"
require "voice_command/railtie"

module VoiceCommand
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def reset_configuration!
      @config = Configuration.new
    end

    def process(audio:, prompt:, context: {}, tool_provider: nil, model: nil, chat_options: {})
      Processor.new(
        audio: audio,
        prompt: prompt,
        context: context,
        tool_provider: tool_provider,
        model: model,
        chat_options: chat_options
      ).process
    end
  end
end
