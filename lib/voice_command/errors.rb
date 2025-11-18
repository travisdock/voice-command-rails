module VoiceCommand
  module Errors
    class Error < StandardError; end
    class MissingAudio < Error; end
    class InvalidAudio < Error; end
    class ProcessingFailed < Error; end
  end
end
