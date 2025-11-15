# frozen_string_literal: true

module VoiceCommandRails
  # Manages the discovery, registration, and retrieval of voice command tools
  #
  # The ToolRegistry automatically discovers tool classes from the Rails
  # application's app/voice_tools/ directory and provides them to the
  # CommandProcessor for AI function calling.
  #
  # @example Auto-discovery
  #   # Tools in app/voice_tools/**/*_tool.rb are automatically discovered
  #   ToolRegistry.all # => [CreateTaskTool, UpdateTaskTool, ...]
  #
  # @example Manual registration
  #   ToolRegistry.register(CustomTool)
  #
  # @example Building context
  #   context = ToolRegistry.context_for(user: current_user)
  #   # => { tasks: [...], projects: [...] }
  class ToolRegistry
    class << self
      # Returns all discovered and registered tools
      #
      # Tools are lazy-loaded and cached after first access
      #
      # @return [Array<VoiceCommandRails::Tool>] array of tool instances
      def all
        @tools ||= discover_tools
      end

      # Manually register a tool class
      #
      # Useful for tools that don't follow the standard naming convention
      # or are defined outside the app/voice_tools/ directory
      #
      # @param tool_class [Class] the tool class to register
      # @return [Array<VoiceCommandRails::Tool>] updated array of tools
      #
      # @example
      #   ToolRegistry.register(MyCustomTool)
      def register(tool_class)
        tool_instance = tool_class.new
        all << tool_instance unless all.any? { |t| t.class == tool_class }
        all
      end

      # Builds context for the AI using the configured context_builder
      #
      # @param user [User] the current user
      # @return [Hash] context data to send to the AI
      #
      # @example
      #   context = ToolRegistry.context_for(user: current_user)
      #   # => { tasks: [{ id: 1, title: "Review PR" }] }
      def context_for(user:)
        VoiceCommandRails.configuration.context_builder.call(user: user)
      rescue StandardError => e
        Rails.logger.error "[VoiceCommandRails] Error building context: #{e.message}"
        {}
      end

      # Clears the tool cache, forcing re-discovery on next access
      #
      # Useful in development when tools are modified
      #
      # @return [nil]
      def clear!
        @tools = nil
      end

      # Returns the number of registered tools
      #
      # @return [Integer]
      def count
        all.size
      end

      # Checks if any tools are registered
      #
      # @return [Boolean]
      def any?
        all.any?
      end

      private

      # Discovers tool classes from the Rails application's app/voice_tools/ directory
      #
      # @return [Array<VoiceCommandRails::Tool>] array of tool instances
      def discover_tools
        tools = []

        # Only attempt discovery if we're in a Rails application
        return tools unless defined?(Rails) && Rails.application

        # Look for tool files in the Rails app
        tool_files = Dir[Rails.root.join("app/voice_tools/**/*_tool.rb")]

        tool_files.each do |file_path|
          begin
            # Require the file
            require file_path

            # Infer class name from file name
            # e.g., "create_task_tool.rb" => "CreateTaskTool"
            class_name = File.basename(file_path, ".rb").camelize

            # Try to constantize the class
            tool_class = class_name.safe_constantize

            if tool_class && tool_class < VoiceCommandRails::Tool
              tools << tool_class.new
              Rails.logger.debug "[VoiceCommandRails] Discovered tool: #{class_name}"
            else
              Rails.logger.warn "[VoiceCommandRails] File #{file_path} does not define a valid tool class"
            end
          rescue StandardError => e
            Rails.logger.error "[VoiceCommandRails] Error loading tool from #{file_path}: #{e.message}"
          end
        end

        if tools.empty?
          Rails.logger.info "[VoiceCommandRails] No tools found in app/voice_tools/"
        else
          Rails.logger.info "[VoiceCommandRails] Discovered #{tools.size} tool(s)"
        end

        tools
      end
    end
  end
end
