# frozen_string_literal: true

require "ruby_llm"

module VoiceCommandRails
  # Base class for defining voice-callable tools
  #
  # Inherits from RubyLLM::Tool to leverage the tool calling infrastructure
  # while providing Rails-specific conveniences.
  #
  # @example Define a simple tool
  #   class CreateTaskTool < VoiceCommandRails::Tool
  #     description "Create a new task with a title"
  #
  #     params do
  #       string :title, description: "The task title"
  #     end
  #
  #     def execute(title:)
  #       task = Current.user.tasks.create!(title: title)
  #       "Created task: #{task.title}"
  #     end
  #   end
  #
  # @example Tool with optional parameters
  #   class CreateTaskTool < VoiceCommandRails::Tool
  #     description "Create a new task"
  #
  #     params do
  #       string :title
  #       any_of :due_date do
  #         string
  #         null
  #       end
  #     end
  #
  #     def execute(title:, due_date: nil)
  #       # Implementation
  #     end
  #   end
  class Tool < RubyLLM::Tool
    class << self
      # Simplified parameter definition for common cases
      #
      # @param name [Symbol] parameter name
      # @param type [Symbol] parameter type (:string, :integer, :boolean)
      # @param desc [String] parameter description
      # @param required [Boolean] whether the parameter is required
      # @param enum [Array] allowed values for string parameters
      #
      # @example
      #   param :title, desc: "Task title"
      #   param :priority, type: :string, desc: "Priority level", enum: %w[low medium high]
      #   param :completed, type: :boolean, desc: "Is completed", required: false
      def param(name, type: :string, desc: nil, required: true, enum: nil)
        params do
          if required
            send(type, name, description: desc).tap do |_|
              instance_variable_get(:@schema)[:required] ||= []
              instance_variable_get(:@schema)[:required] << name.to_s
            end
          else
            any_of name, description: desc do
              if enum
                string enum: enum
              else
                send(type)
              end
              null
            end
          end
        end
      end
    end

    # Override to provide access to current user context
    #
    # Tools can access Current.user to perform user-scoped operations
    #
    # @return [Object] result that will be sent back to the AI
    def execute(**args)
      raise NotImplementedError, "#{self.class}#execute must be implemented"
    end

    private

    # Helper to access current user
    #
    # @return [User, nil] the current user
    def current_user
      defined?(Current) ? Current.user : nil
    end

    # Helper to check if user is present
    #
    # @return [Boolean]
    def user_signed_in?
      current_user.present?
    end

    # Log a message if tool logging is enabled
    #
    # @param message [String] the message to log
    def log_tool_execution(message)
      return unless VoiceCommandRails.configuration.log_tool_calls

      Rails.logger.info "[VoiceCommandRails::Tool] #{self.class.name}: #{message}"
    end
  end
end
