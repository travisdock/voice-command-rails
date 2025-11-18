require_relative "base"

module VoiceCommand
  module Providers
    # Gemini provider using ruby_llm gem (supports audio transcription and tool calling)
    class GeminiProvider < Base
      def process_audio(audio_file_path, prompt, tools: [], context: {})
        require "ruby_llm" unless defined?(RubyLLM)

        @context = context
        configure_ruby_llm

        log_event("processing_started", audio_file: audio_file_path, tool_count: tools.length)

        # Initialize chat with Gemini
        chat = RubyLLM.chat(model: @config.model || "gemini-2.0-flash")

        # Create tool instances and add them to the chat
        # Note: For RubyLLM, we need to wrap our tools or make them compatible
        # For now, we'll create instances and pass them directly
        tool_instances = tools.map { |tool_class| tool_class.new(context: @context) }

        tool_instances.each do |tool|
          chat.with_tool(tool)
        end

        log_event("gemini_request_sent", prompt_length: prompt.length, tool_count: tools.length)

        api_start = Time.current
        # RubyLLM handles both audio transcription and tool calling in one call
        response = chat.ask(prompt, with: audio_file_path)
        api_duration = ((Time.current - api_start) * 1000).round

        log_event("gemini_response_received", response_length: response.length, duration_ms: api_duration)

        response
      rescue => e
        log_event("processing_failed", error: e.message, error_class: e.class.name)
        raise ProviderError, "Gemini processing failed: #{e.message}"
      end

      private

      def configure_ruby_llm
        api_key = @config.gemini_api_key || ENV["GEMINI_API_KEY"]
        raise ConfigurationError, "Gemini API key not configured" unless api_key

        RubyLLM.configure do |config|
          config.gemini_api_key = api_key
        end
      end
    end
  end
end
