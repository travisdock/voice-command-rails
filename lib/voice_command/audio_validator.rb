module VoiceCommand
  class AudioValidator
    attr_reader :upload, :config

    def initialize(upload, config: VoiceCommand.config)
      @upload = upload
      @config = config
    end

    def validate!
      raise Errors::MissingAudio, "No audio file was provided." unless upload

      unless allowed_content_type?
        raise Errors::InvalidAudio,
          "Unsupported audio file. Allowed content types: #{Array(config.allowed_content_types).join(', ')}"
      end

      if too_large?
        raise Errors::InvalidAudio,
          "Audio file is too large. Maximum size is #{config.audio_max_bytes} bytes."
      end

      true
    end

    def size
      return unless upload
      return upload.size if upload.respond_to?(:size)
      file = upload.respond_to?(:tempfile) ? upload.tempfile : upload
      file&.size
    end

    def path
      return unless upload

      file = upload.respond_to?(:tempfile) ? upload.tempfile : upload
      file.respond_to?(:path) ? file.path : nil
    end

    def content_type
      return unless upload
      upload.respond_to?(:content_type) ? upload.content_type : nil
    end

    private

    def allowed_content_type?
      allowed = Array(config.allowed_content_types)
      return true if allowed.empty?

      type = content_type.to_s
      return false if type.empty?

      allowed.any? do |rule|
        case rule
        when String
          type.start_with?(rule)
        when Regexp
          rule.match?(type)
        when Proc
          rule.call(type)
        else
          false
        end
      end
    end

    def too_large?
      return false unless size && config.audio_max_bytes
      size > config.audio_max_bytes
    end
  end
end
