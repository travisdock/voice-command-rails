# frozen_string_literal: true

require "ruby_llm"

module VoiceCommandRails
  # Processes voice commands by orchestrating audio transcription and tool execution
  #
  # This service coordinates the entire voice command flow:
  # 1. Gathers context from the application
  # 2. Initializes AI chat with configured model
  # 3. Registers available tools
  # 4. Sends audio for transcription and analysis
  # 5. Executes tool calls
  # 6. Returns formatted response
  #
  # @example Basic usage
  #   processor = CommandProcessor.new(user: current_user, audio_file: tempfile)
  #   result = processor.process
  #   # => { success: true, message: "Created task: Review PR", timestamp: Time.current }
  #
  # @example Error handling
  #   result = processor.process
  #   if result[:success]
  #     puts result[:message]
  #   else
  #     puts "Error: #{result[:message]}"
  #   end
  class CommandProcessor
    attr_reader :user, :audio_file

    # Initialize a new command processor
    #
    # @param user [User] the current user
    # @param audio_file [Tempfile, File] the audio file to process
    def initialize(user:, audio_file:)
      @user = user
      @audio_file = audio_file
      @config = VoiceCommandRails.configuration
    end

    # Process the voice command
    #
    # @return [Hash] result with :success, :message, and :timestamp keys
    def process
      log_start

      # Gather context
      context = ToolRegistry.context_for(user: user)

      # Initialize chat
      chat = initialize_chat

      # Register tools
      register_tools(chat)

      # Build prompt
      prompt = build_prompt_with_context(context)

      # Send audio and get response
      response = send_audio_request(chat, prompt)

      # Extract message
      message = extract_message(response)

      log_success(message)

      {
        success: true,
        message: message,
        timestamp: Time.current
      }
    rescue RubyLLM::Error => e
      log_error(e, "RubyLLM API error")
      {
        success: false,
        message: "Sorry, I couldn't process that command. Please try again.",
        error: e.message,
        timestamp: Time.current
      }
    rescue StandardError => e
      log_error(e, "Unexpected error")
      {
        success: false,
        message: "An unexpected error occurred. Please try again.",
        error: e.message,
        timestamp: Time.current
      }
    end

    private

    # Initialize RubyLLM chat with configured model and temperature
    #
    # @return [RubyLLM::Chat]
    def initialize_chat
      chat = RubyLLM.chat(model: @config.model)
      chat.with_temperature(@config.temperature)
      chat.with_instructions(@config.system_prompt)
      chat
    end

    # Register all discovered tools with the chat
    #
    # @param chat [RubyLLM::Chat]
    def register_tools(chat)
      tools = ToolRegistry.all

      if tools.empty?
        Rails.logger.warn "[VoiceCommandRails] No tools registered - AI will only provide text responses"
        return
      end

      tools.each do |tool|
        chat.with_tool(tool)
      end

      log_tools_registered(tools.size)
    end

    # Build the prompt with application context
    #
    # @param context [Hash] context data from the application
    # @return [String] the complete prompt
    def build_prompt_with_context(context)
      if context.empty?
        return "Process this voice command and use the available tools to help the user."
      end

      context_json = JSON.pretty_generate(context)

      <<~PROMPT
        Here is the current context from the application:

        #{context_json}

        Process the voice command and use the available tools to help the user.
        Use the context above to understand what data is available and make informed decisions.
      PROMPT
    end

    # Send audio file to AI for transcription and processing
    #
    # @param chat [RubyLLM::Chat]
    # @param prompt [String]
    # @return [RubyLLM::Response]
    def send_audio_request(chat, prompt)
      log_request_sent

      response = chat.ask(prompt, with: @audio_file.path)

      log_response_received(response)

      response
    end

    # Extract the message text from the response
    #
    # @param response [RubyLLM::Response]
    # @return [String]
    def extract_message(response)
      if response.respond_to?(:content)
        response.content
      elsif response.respond_to?(:text)
        response.text
      else
        response.to_s
      end
    end

    # Logging methods

    def log_start
      return unless @config.log_tool_calls

      Rails.logger.info "[VoiceCommandRails] Processing voice command for user #{user.id}"
      Rails.logger.debug "[VoiceCommandRails] Audio file size: #{@audio_file.size} bytes"
    end

    def log_tools_registered(count)
      return unless @config.log_tool_calls

      Rails.logger.info "[VoiceCommandRails] Registered #{count} tool(s) with AI"
    end

    def log_request_sent
      return unless @config.log_tool_calls

      Rails.logger.info "[VoiceCommandRails] Sending audio to #{@config.model}"
    end

    def log_response_received(response)
      return unless @config.log_tool_calls

      Rails.logger.info "[VoiceCommandRails] Received response from AI"

      if response.respond_to?(:input_tokens) && response.respond_to?(:output_tokens)
        Rails.logger.debug "[VoiceCommandRails] Tokens: #{response.input_tokens} in, #{response.output_tokens} out"
      end
    end

    def log_success(message)
      return unless @config.log_tool_calls

      Rails.logger.info "[VoiceCommandRails] Successfully processed command"

      if @config.log_transcriptions
        Rails.logger.debug "[VoiceCommandRails] Response: #{message.truncate(200)}"
      end
    end

    def log_error(error, context)
      Rails.logger.error "[VoiceCommandRails] #{context}: #{error.class} - #{error.message}"
      Rails.logger.debug error.backtrace.join("\n") if Rails.env.development?
    end
  end
end
