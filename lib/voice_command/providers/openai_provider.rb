require_relative "base"

module VoiceCommand
  module Providers
    # OpenAI provider for audio transcription and chat completion with function calling
    class OpenAIProvider < Base
      def process_audio(audio_file_path, prompt, tools: [], context: {})
        require "openai" unless defined?(OpenAI)

        @context = context
        client = openai_client

        # Step 1: Transcribe audio to text
        log_event("transcription_started", audio_file: audio_file_path)
        transcription = transcribe_audio(client, audio_file_path)
        log_event("transcription_completed", transcription_length: transcription.length)

        # Step 2: Process with chat completion and tools
        log_event("chat_started", prompt_length: prompt.length, tool_count: tools.length)
        response = chat_with_tools(client, prompt, transcription, tools)
        log_event("chat_completed", response_length: response.length)

        response
      rescue => e
        log_event("processing_failed", error: e.message, error_class: e.class.name)
        raise ProviderError, "OpenAI processing failed: #{e.message}"
      end

      private

      def openai_client
        OpenAI::Client.new(
          access_token: @config.openai_api_key || ENV["OPENAI_API_KEY"],
          request_timeout: 120
        )
      end

      def transcribe_audio(client, audio_file_path)
        response = client.audio.transcribe(
          parameters: {
            model: "whisper-1",
            file: File.open(audio_file_path, "rb"),
            response_format: "json"
          }
        )
        response["text"]
      end

      def chat_with_tools(client, prompt, transcription, tools)
        messages = [
          { role: "system", content: prompt },
          { role: "user", content: transcription }
        ]

        # Create tool instances (tools are tool classes at this point)
        tool_instances = tools.map { |tool_class| tool_class.new }

        # Convert tools to OpenAI function format
        functions = tool_instances.map { |tool| tool.to_openai_function }

        loop do
          parameters = {
            model: @config.model,
            messages: messages
          }

          # Add functions if any tools are registered
          parameters[:tools] = functions.map { |f| { type: "function", function: f } } if functions.any?
          parameters[:tool_choice] = "auto" if functions.any?

          response = client.chat(parameters: parameters)
          message = response.dig("choices", 0, "message")

          # Add assistant's response to messages
          messages << message

          # Check if the model wants to call a function
          if message["tool_calls"]
            # Execute each tool call
            message["tool_calls"].each do |tool_call|
              function_name = tool_call.dig("function", "name")
              arguments = JSON.parse(tool_call.dig("function", "arguments"))

              # Find and execute the tool
              tool = tool_instances.find { |t| t.class.tool_name == function_name }
              result = if tool
                         # Execute with arguments, context will be passed by processor
                         tool.execute(**arguments.symbolize_keys.merge(context: @context || {}))
                       else
                         "Error: Tool '#{function_name}' not found"
                       end

              # Add tool result to messages
              messages << {
                role: "tool",
                tool_call_id: tool_call["id"],
                name: function_name,
                content: result.to_s
              }
            end
          else
            # No more tool calls, return final response
            return message["content"] || "I've processed your request."
          end
        end
      end
    end
  end
end
