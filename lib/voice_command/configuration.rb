require "active_support/core_ext/numeric/bytes"
require "logger"

module VoiceCommand
  class Configuration
    attr_accessor :logger,
                  :audio_max_bytes,
                  :allowed_content_types,
                  :llm_model

    attr_writer :tool_provider, :chat_factory

    def initialize
      @logger = defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : Logger.new($stdout)
      @audio_max_bytes = 5.megabytes
      @allowed_content_types = ["audio/"]
      @llm_model = "gemini-2.0-flash"
      @tool_provider = ->(_context) { [] }
      @chat_factory = default_chat_factory
    end

    def tool_provider
      @tool_provider || ->(_context) { [] }
    end

    def chat_factory
      @chat_factory || default_chat_factory
    end

    private

    def default_chat_factory
      lambda do |model:, **_options|
        RubyLLM.chat(model: model)
      end
    end
  end
end
