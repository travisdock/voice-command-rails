# frozen_string_literal: true

class <%= tool_class_name %>Tool < VoiceCommandRails::Tool
  description "<%= tool_description %>"

  # Define parameters that the AI can pass to this tool
  # Examples:
  #
  # param :title, type: :string, desc: "The title of the item", required: true
  # param :due_date, type: :string, desc: "The due date in ISO format (YYYY-MM-DD)", required: false
  # param :priority, type: :string, desc: "Priority level", enum: ["low", "medium", "high"], required: false
  # param :count, type: :integer, desc: "How many items", required: false
  #
  # Available types: :string, :integer, :number, :boolean, :array, :object

  # Add your parameters here
  # param :example_param, type: :string, desc: "An example parameter"

  def execute(**args)
    # Access the current user (if available)
    # user = current_user

    # Implement your tool logic here
    # Use the args hash to access parameters passed by the AI
    # Example: title = args[:title]

    # Return a user-friendly message that will be displayed
    # Example: "Task '#{title}' created successfully!"

    raise NotImplementedError, "Implement the execute method in #{self.class.name}"
  end

  private

  # Add any helper methods here
end
