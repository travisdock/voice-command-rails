module VoiceCommand
  # Core processor for voice command handling
  # Orchestrates audio validation, rate limiting, LLM interaction, and tool execution
  class Processor
    attr_reader :audio_file, :user, :context_builder, :prompt_template

    # Initialize the processor
    # @param audio_file [Tempfile, File] The audio file to process
    # @param user [Object] The user making the request (for rate limiting and context)
    # @param context_builder [Proc] Lambda/proc that builds context for the LLM prompt
    # @param prompt_template [Proc] Lambda/proc that takes context and returns the full prompt
    def initialize(audio_file:, user: nil, context_builder: nil, prompt_template: nil)
      @audio_file = audio_file
      @user = user
      @context_builder = context_builder || -> { "" }
      @prompt_template = prompt_template || ->(ctx) { ctx.to_s }
    end

    # Process the audio file and return a result
    # @return [VoiceCommand::Result] Success or failure result
    def process
      # Validate audio file
      validate_audio!

      # Check rate limit
      check_rate_limit!

      # Build context and prompt
      context = @context_builder.call
      prompt = @prompt_template.call(context)

      # Log processing start
      log_event("processing_started", audio_size: audio_file_size)

      # Get provider and process
      provider = VoiceCommand.configuration.provider_instance
      registered_tools = VoiceCommand.configuration.tools

      # Build context hash for tools
      tool_context = {
        user: @user,
        timestamp: Time.current
      }

      # Process audio with provider
      response = provider.process_audio(
        @audio_file.path,
        prompt,
        tools: registered_tools,
        context: tool_context
      )

      log_event("processing_completed", response_length: response.length)

      Result.success(response: response)
    rescue RateLimitExceeded => e
      log_event("rate_limit_exceeded", user_id: @user&.id)
      Result.failure(error: "Rate limit exceeded. Please try again later.")
    rescue InvalidAudioFile, FileTooLarge => e
      log_event("validation_failed", error: e.message)
      Result.failure(error: e.message)
    rescue ProviderError => e
      log_event("provider_error", error: e.message)
      Result.failure(error: "An error occurred processing your request: #{e.message}")
    rescue StandardError => e
      log_event("processing_failed", error: e.message, error_class: e.class.name)
      Result.failure(error: "An unexpected error occurred processing your request.")
    end

    private

    def validate_audio!
      require "voice_command/validators/audio_validator"
      Validators::AudioValidator.validate!(@audio_file)
    end

    def check_rate_limit!
      require "voice_command/validators/rate_limiter"
      Validators::RateLimiter.check!(@user)
    end

    def audio_file_size
      @audio_file.respond_to?(:size) ? @audio_file.size : File.size(@audio_file.path)
    end

    def log_event(event, metadata = {})
      logger = VoiceCommand.configuration.effective_logger
      logger.info({
        event: event,
        component: "VoiceCommand::Processor",
        user_id: @user&.id,
        timestamp: Time.current.iso8601
      }.merge(metadata).to_json)
    end
  end
end
