module VoiceCommand
  module Validators
    # Validates audio files before processing
    class AudioValidator
      class << self
        # Validate an audio file
        # @param audio_file [Tempfile, File] The audio file to validate
        # @raise [InvalidAudioFile] If file is invalid
        # @raise [FileTooLarge] If file exceeds size limit
        # @return [true] If validation passes
        def validate!(audio_file)
          config = VoiceCommand.configuration

          # Check file exists
          raise InvalidAudioFile, "No audio file provided" unless audio_file
          raise InvalidAudioFile, "Invalid file object" unless audio_file.respond_to?(:path)

          # Check file path exists
          unless File.exist?(audio_file.path)
            raise InvalidAudioFile, "Audio file does not exist at path: #{audio_file.path}"
          end

          # Content type validation
          content_type = detect_content_type(audio_file)
          unless valid_content_type?(content_type, config.allowed_content_types)
            raise InvalidAudioFile,
                  "Invalid audio format: #{content_type}. Allowed: #{config.allowed_content_types.join(', ')}"
          end

          # File size validation
          size = audio_file.respond_to?(:size) ? audio_file.size : File.size(audio_file.path)
          if size > config.max_file_size
            raise FileTooLarge,
                  "File size #{format_bytes(size)} exceeds maximum #{format_bytes(config.max_file_size)}"
          end

          true
        end

        private

        def detect_content_type(file)
          # Use Marcel gem for reliable MIME detection
          require "marcel"
          Marcel::MimeType.for(file)
        rescue LoadError
          # Fallback to file extension if Marcel not available
          extension = File.extname(file.path).downcase
          case extension
          when ".webm" then "audio/webm"
          when ".mp3", ".mpeg" then "audio/mpeg"
          when ".mp4", ".m4a" then "audio/mp4"
          when ".ogg" then "audio/ogg"
          when ".wav" then "audio/wav"
          else "application/octet-stream"
          end
        end

        def valid_content_type?(content_type, allowed_types)
          allowed_types.any? { |type| content_type.start_with?(type) }
        end

        def format_bytes(bytes)
          if bytes < 1024
            "#{bytes} bytes"
          elsif bytes < 1024 * 1024
            "#{(bytes / 1024.0).round(2)} KB"
          else
            "#{(bytes / 1024.0 / 1024.0).round(2)} MB"
          end
        end
      end
    end
  end
end
