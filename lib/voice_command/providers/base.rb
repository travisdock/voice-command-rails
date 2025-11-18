module VoiceCommand
  module Providers
    # Base class for all LLM providers
    # Subclasses must implement #process_audio
    class Base
      attr_reader :config

      def initialize(config)
        @config = config
      end

      # Process audio file and return LLM response
      # @param audio_file_path [String] Path to the audio file
      # @param prompt [String] The prompt to send to the LLM
      # @param tools [Array<Class>] Array of tool classes
      # @param context [Hash] Context to pass to tools (user, etc.)
      # @return [String] The LLM's response
      # @raise [ProviderError] If processing fails
      def process_audio(audio_file_path, prompt, tools: [], context: {})
        raise NotImplementedError, "Subclasses must implement #process_audio"
      end

      protected

      # Get the effective logger from config
      def logger
        @config.effective_logger
      end

      # Log an event
      def log_event(event, metadata = {})
        logger.info({
          event: event,
          provider: self.class.name.split("::").last,
          timestamp: Time.current.iso8601
        }.merge(metadata).to_json)
      end
    end
  end
end
