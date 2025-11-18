require "json"

module VoiceCommand
  class Processor
    attr_reader :audio,
                :prompt,
                :context,
                :tool_provider,
                :model,
                :chat_options,
                :logger

    def initialize(audio:, prompt:, context: {}, tool_provider: nil, model: nil, chat_options: {}, logger: nil)
      @audio = audio
      @prompt = prompt
      @context = context || {}
      @tool_provider = tool_provider
      @model = model || VoiceCommand.config.llm_model
      @chat_options = chat_options || {}
      @logger = logger || VoiceCommand.config.logger
      @validator = AudioValidator.new(audio)
    end

    def process
      raise Errors::MissingAudio, "No audio file was provided." unless audio
      raise Errors::InvalidAudio, "Prompt must be present." if prompt.to_s.strip.empty?

      @validator.validate!

      started_at = Time.current
      audio_size = @validator.size

      log(:info, "voice_command_started", audio_size_bytes: audio_size)

      audio_path = @validator.path
      raise Errors::InvalidAudio, "Audio file could not be read." unless audio_path

      chat = build_chat
      attach_tools(chat)

      api_start = Time.current
      response = chat.ask(prompt, with: audio_path)
      api_duration = elapsed_ms(api_start)

      log(:info, "voice_command_response_received", duration_ms: api_duration)

      message_text = extract_text(response)
      total_duration = elapsed_ms(started_at)

      log(:info, "voice_command_complete", total_duration_ms: total_duration, api_duration_ms: api_duration)

      {
        success: true,
        message: message_text,
        raw_response: response,
        metadata: {
          api_duration_ms: api_duration,
          total_duration_ms: total_duration,
          audio_size_bytes: audio_size
        }
      }
    rescue Errors::Error => e
      log(:error, "voice_command_failed", error_class: e.class.name, error_message: e.message)
      failure_response(e)
    rescue => e
      log(:error, "voice_command_failed", error_class: e.class.name, error_message: e.message)
      raise Errors::ProcessingFailed, e.message
    end

    private

    def elapsed_ms(start_time)
      ((Time.current - start_time) * 1000).round
    end

    def build_chat
      VoiceCommand.config.chat_factory.call(**{ model: model }.merge(chat_options))
    end

    def attach_tools(chat)
      provider = tool_provider || VoiceCommand.config.tool_provider
      Array(provider.call(context)).each do |tool|
        next unless tool
        chat.with_tool(tool)
      end
    rescue NoMethodError => e
      raise Errors::ProcessingFailed, "Tool provider must respond to #call and return enumerable tools. #{e.message}"
    end

    def extract_text(response)
      if response.respond_to?(:content)
        response.content
      elsif response.respond_to?(:text)
        response.text
      else
        response.to_s
      end
    end

    def failure_response(error)
      {
        success: false,
        message: error.message,
        error: error
      }
    end

    def log(level, event, payload = {})
      logger.public_send(level, "[VoiceCommand] #{event} #{payload.to_json}")
    rescue StandardError
      # Ignore logging failures so voice commands still work.
      nil
    end
  end
end
