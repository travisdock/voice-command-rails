require_relative "base"

module VoiceCommand
  module Providers
    # Anthropic provider (Claude) - Note: Anthropic doesn't support audio transcription
    # This provider requires pre-transcribed text or uses a different transcription service
    class AnthropicProvider < Base
      def process_audio(audio_file_path, prompt, tools: [])
        raise ProviderError, "Anthropic does not support direct audio transcription. Please use OpenAI or Gemini for audio processing, or provide pre-transcribed text."
      end

      # Process with pre-transcribed text
      # @param text [String] The transcribed text
      # @param prompt [String] The system prompt
      # @param tools [Array<Class>] Array of tool classes
      # @param context [Hash] Context to pass to tools
      # @return [String] The LLM's response
      def process_text(text, prompt, tools: [], context: {})
        require "anthropic" unless defined?(Anthropic)

        @context = context
        client = anthropic_client

        log_event("chat_started", prompt_length: prompt.length, text_length: text.length, tool_count: tools.length)
        response = chat_with_tools(client, prompt, text, tools)
        log_event("chat_completed", response_length: response.length)

        response
      rescue => e
        log_event("processing_failed", error: e.message, error_class: e.class.name)
        raise ProviderError, "Anthropic processing failed: #{e.message}"
      end

      private

      def anthropic_client
        Anthropic::Client.new(
          api_key: @config.anthropic_api_key || ENV["ANTHROPIC_API_KEY"],
          request_options: {
            timeout: 120
          }
        )
      end

      def chat_with_tools(client, prompt, text, tools)
        messages = [ { role: "user", content: text } ]

        # Create tool instances (tools are tool classes at this point)
        tool_instances = tools.map { |tool_class| tool_class.new }

        # Convert tools to Anthropic tool format
        anthropic_tools = tool_instances.map { |tool| tool.to_anthropic_tool }

        loop do
          parameters = {
            model: @config.model || "claude-sonnet-4-5-20250929",
            max_tokens: 1024,
            system: prompt,
            messages: messages
          }

          # Add tools if any are registered
          parameters[:tools] = anthropic_tools if anthropic_tools.any?

          response = client.messages.create(**parameters)

          # Check if Claude wants to use a tool
          if response.stop_reason == "tool_use"
            tool_use_block = response.content.find { |block| block["type"] == "tool_use" }

            # Find and execute the tool
            tool_name = tool_use_block["name"]
            tool = tool_instances.find { |t| t.class.tool_name == tool_name }

            result = if tool
                       tool.execute(**tool_use_block["input"].symbolize_keys.merge(context: @context || {}))
                     else
                       "Error: Tool '#{tool_name}' not found"
                     end

            # Add assistant's response and tool result to messages
            messages << { role: "assistant", content: response.content }
            messages << {
              role: "user",
              content: [
                {
                  type: "tool_result",
                  tool_use_id: tool_use_block["id"],
                  content: result.to_s
                }
              ]
            }
          else
            # No more tools needed, return final response
            text_content = response.content.find { |block| block["type"] == "text" }
            return text_content ? text_content["text"] : "I've processed your request."
          end
        end
      end
    end
  end
end
