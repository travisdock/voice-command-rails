module VoiceCommand
  # Base error class for all VoiceCommand errors
  class Error < StandardError; end

  # Raised when audio file validation fails
  class InvalidAudioFile < Error; end

  # Raised when audio file exceeds size limit
  class FileTooLarge < Error; end

  # Raised when rate limit is exceeded
  class RateLimitExceeded < Error; end

  # Raised when configuration is invalid
  class ConfigurationError < Error; end

  # Raised when a provider encounters an error
  class ProviderError < Error; end
end
