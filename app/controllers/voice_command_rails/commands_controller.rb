# frozen_string_literal: true

module VoiceCommandRails
  # Handles voice command uploads and processing
  #
  # This controller receives audio files from the JavaScript frontend,
  # validates them, checks rate limits, and delegates processing to
  # the CommandProcessor service.
  #
  # @example Route
  #   POST /voice_command_rails/commands
  #
  # @example Request
  #   Content-Type: multipart/form-data
  #   audio: [binary audio file]
  #
  # @example Response (Turbo Stream)
  #   turbo_stream.update("voice_command_status", "Processing...")
  #   turbo_stream.update("voice_command_response", partial: "response")
  class CommandsController < ApplicationController
    # Maximum audio file size (configurable)
    MAX_AUDIO_BYTES = -> { VoiceCommandRails.configuration.max_file_size }

    # Rate limiting configuration (configurable)
    RATE_LIMIT_MAX_REQUESTS = -> { VoiceCommandRails.configuration.rate_limit_max }
    RATE_LIMIT_WINDOW = -> { VoiceCommandRails.configuration.rate_limit_window }

    # Process a voice command
    #
    # Validates the audio file, checks rate limits, processes the command,
    # and returns a Turbo Stream response with the result.
    #
    # @return [TurboStream] Turbo Stream response updating the UI
    def create
      # Get current user (assumes Current.user is set by parent app)
      user = current_user_for_voice_commands

      # Check authorization
      unless user_authorized?(user)
        return respond_to_failure(
          :forbidden,
          "Voice commands are not enabled for your account."
        )
      end

      # Get audio file from params
      audio = params[:audio]

      # Validate audio file presence
      unless audio.respond_to?(:tempfile)
        return respond_to_failure(
          :unprocessable_entity,
          "No audio file detected. Please record audio and try again."
        )
      end

      # Validate audio type
      unless audio_upload_allowed?(audio)
        return respond_to_failure(
          :unprocessable_entity,
          "Unsupported audio format. Please use a supported format (WebM, MP3, WAV, etc.)."
        )
      end

      # Validate audio size
      if audio_upload_too_large?(audio)
        max_mb = (MAX_AUDIO_BYTES.call / 1.megabyte).round
        return respond_to_failure(
          :unprocessable_entity,
          "Audio file too large. Maximum size is #{max_mb} MB."
        )
      end

      # Check rate limit
      if rate_limit_enabled? && rate_limit_exceeded?(user)
        return respond_to_failure(
          :too_many_requests,
          "Too many requests. Please wait a moment and try again."
        )
      end

      # Process the command
      processor = CommandProcessor.new(user: user, audio_file: audio.tempfile)
      result = processor.process

      # Check if processing succeeded
      unless result[:success]
        return respond_to_failure(
          :bad_gateway,
          result[:message] || "Unable to process voice command. Please try again."
        )
      end

      # Return success response
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(
              "voice_command_status",
              partial: "voice_command_rails/status",
              locals: { status: "Ready" }
            ),
            turbo_stream.update(
              "voice_command_response",
              partial: "voice_command_rails/response",
              locals: { message: result[:message], timestamp: result[:timestamp] }
            )
          ]
        end
      end
    end

    private

    # Get the current user for voice commands
    #
    # Override this method in your ApplicationController if you use
    # a different pattern for accessing the current user
    #
    # @return [User, nil]
    def current_user_for_voice_commands
      if defined?(Current) && Current.respond_to?(:user)
        Current.user
      elsif respond_to?(:current_user)
        current_user
      else
        nil
      end
    end

    # Check if user is authorized to use voice commands
    #
    # @param user [User, nil]
    # @return [Boolean]
    def user_authorized?(user)
      return false unless user

      method_name = VoiceCommandRails.configuration.feature_flag_method

      if user.respond_to?(method_name)
        user.public_send(method_name)
      else
        # If the method doesn't exist, default to allowing
        Rails.logger.warn "[VoiceCommandRails] User model doesn't respond to #{method_name}, allowing by default"
        true
      end
    end

    # Check if the uploaded audio file type is allowed
    #
    # @param upload [ActionDispatch::Http::UploadedFile]
    # @return [Boolean]
    def audio_upload_allowed?(upload)
      content_type = upload.content_type.to_s
      allowed_types = VoiceCommandRails.configuration.allowed_mime_types

      allowed_types.any? { |type| content_type.start_with?(type) }
    end

    # Check if the uploaded audio file is too large
    #
    # @param upload [ActionDispatch::Http::UploadedFile]
    # @return [Boolean]
    def audio_upload_too_large?(upload)
      upload.size.to_i > MAX_AUDIO_BYTES.call
    end

    # Check if rate limiting is enabled
    #
    # @return [Boolean]
    def rate_limit_enabled?
      VoiceCommandRails.configuration.rate_limit_enabled
    end

    # Check if the user has exceeded the rate limit
    #
    # Uses Rails.cache to track request counts per user
    #
    # @param user [User]
    # @return [Boolean]
    def rate_limit_exceeded?(user)
      key = "voice_command_rails:rate:#{user.id}"
      window = RATE_LIMIT_WINDOW.call
      max_requests = RATE_LIMIT_MAX_REQUESTS.call

      # Increment counter
      current = Rails.cache.increment(key, 1, expires_in: window)

      # If increment returned nil, the key didn't exist, so initialize it
      unless current
        Rails.cache.write(key, 1, expires_in: window)
        current = 1
      end

      current > max_requests
    end

    # Respond with a failure message
    #
    # @param status [Symbol] HTTP status code symbol
    # @param message [String] error message to display
    def respond_to_failure(status, message)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "voice_command_response",
            partial: "voice_command_rails/error",
            locals: { message: message }
          ), status: status
        end
      end
    end
  end
end
