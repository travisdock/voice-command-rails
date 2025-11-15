# frozen_string_literal: true

module VoiceCommandRails
  class Configuration
    attr_accessor :model,
                  :temperature,
                  :system_prompt,
                  :context_builder,
                  :max_file_size,
                  :allowed_mime_types,
                  :rate_limit_enabled,
                  :rate_limit_max,
                  :rate_limit_window,
                  :button_position,
                  :enable_auto_fade,
                  :fade_delay,
                  :feature_flag_method,
                  :log_transcriptions,
                  :log_tool_calls,
                  :custom_button_class,
                  :custom_container_class,
                  :custom_message_class

    def initialize
      # AI Configuration
      @model = "gemini-2.5-flash"
      @temperature = 0.3
      @system_prompt = default_system_prompt

      # Context Building
      @context_builder = ->(user:) { {} }

      # File Upload
      @max_file_size = 5.megabytes
      @allowed_mime_types = %w[audio/webm audio/mp4 audio/mpeg audio/wav audio/ogg audio/flac]

      # Rate Limiting
      @rate_limit_enabled = true
      @rate_limit_max = 5
      @rate_limit_window = 1.minute

      # UI
      @button_position = :bottom_right
      @enable_auto_fade = true
      @fade_delay = 5.seconds

      # Custom CSS classes (optional - for framework integration)
      @custom_button_class = nil
      @custom_container_class = nil
      @custom_message_class = nil

      # Feature Flags
      @feature_flag_method = :voice_commands_enabled?

      # Logging
      @log_transcriptions = Rails.env.development?
      @log_tool_calls = true
    end

    private

    def default_system_prompt
      <<~PROMPT
        You are a helpful voice assistant for a Rails application.
        When the user gives you a voice command, use the available tools to perform actions.
        Always use tools to make changes - never just describe what you would do.
        Be concise and friendly in your responses.
      PROMPT
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
