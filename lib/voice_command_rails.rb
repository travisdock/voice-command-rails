require "voice_command_rails/version"
require "voice_command_rails/configuration"
require "voice_command_rails/tool"
require "voice_command_rails/engine"

module VoiceCommandRails
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ToolNotFoundError < Error; end
  class AudioTooLargeError < Error; end
  class RateLimitExceededError < Error; end
  class UnsupportedAudioFormatError < Error; end
end
