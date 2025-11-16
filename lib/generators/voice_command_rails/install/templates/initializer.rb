# frozen_string_literal: true

VoiceCommandRails.configure do |config|
  # AI Model Configuration
  # ----------------------
  # The Gemini model to use for audio transcription and tool calling
  # Default: "gemini-2.5-flash"
  # config.model = "gemini-2.5-flash"

  # Temperature for AI responses (0.0 - 2.0)
  # Lower values = more focused, higher values = more creative
  # Default: 0.7
  # config.temperature = 0.7

  # System prompt for the AI
  # This instructs the AI on how to interpret voice commands
  # Default: "You are a helpful assistant..."
  # config.system_prompt = "You are a helpful assistant that processes voice commands..."

  # Context Builder
  # ---------------
  # Provide additional context to the AI for each request
  # Receives the current user and should return a hash
  # Example:
  # config.context_builder = ->(user:) {
  #   {
  #     user_name: user.name,
  #     current_tasks: user.tasks.pluck(:id, :title),
  #     preferences: user.preferences
  #   }
  # }

  # File Upload Restrictions
  # ------------------------
  # Maximum audio file size in bytes
  # Default: 10MB (10_485_760 bytes)
  # config.max_file_size = 10_485_760

  # Allowed audio MIME types
  # Default: ["audio/mpeg", "audio/mp4", "audio/webm", "audio/wav", "audio/ogg", "audio/flac"]
  # config.allowed_mime_types = ["audio/mpeg", "audio/mp4", "audio/webm", "audio/wav", "audio/ogg", "audio/flac"]

  # Rate Limiting
  # -------------
  # Enable rate limiting to prevent abuse
  # Default: true
  # config.rate_limit_enabled = true

  # Maximum requests per time window
  # Default: 10
  # config.rate_limit_max = 10

  # Time window in seconds
  # Default: 60 (1 minute)
  # config.rate_limit_window = 60

  # UI Configuration
  # ----------------
  # Button position: :bottom_right, :bottom_left, :top_right, :top_left
  # Default: :bottom_right
  # config.button_position = :bottom_right

  # Enable auto-fade for success messages
  # Default: true
  # config.enable_auto_fade = true

  # Delay before auto-fade in milliseconds
  # Default: 5000 (5 seconds)
  # config.fade_delay = 5000

  # Custom CSS Classes
  # ------------------
  # Add your own CSS classes to customize the appearance
  # These classes will be added alongside the default classes

  # Custom classes for the microphone button
  # Example: "btn btn-primary btn-lg"
  # config.custom_button_class = ""

  # Custom classes for the message container
  # Example: "card shadow-lg"
  # config.custom_container_class = ""

  # Custom classes for individual messages
  # Example: "alert alert-info"
  # config.custom_message_class = ""

  # Feature Flags
  # -------------
  # Method to check if voice commands are enabled for a user
  # Default: :voice_commands_enabled?
  # config.feature_flag_method = :voice_commands_enabled?

  # Logging
  # -------
  # Log audio transcriptions for debugging
  # Default: Rails.env.development?
  # config.log_transcriptions = Rails.env.development?

  # Log tool calls for debugging
  # Default: Rails.env.development?
  # config.log_tool_calls = Rails.env.development?

  # Custom Error Handlers
  # ---------------------
  # Handle errors from tool execution
  # config.error_handler = ->(error, user:, audio_file:) {
  #   ErrorNotifier.notify(error, user: user)
  #   "Sorry, something went wrong processing your command."
  # }
end
