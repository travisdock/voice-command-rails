class ExampleTool < VoiceCommand::Tool
  description "An example tool that echoes back a message with a greeting"

  params do
    string :message, description: "The message to echo back"
    string :greeting, description: "Optional greeting", default: "Hello"
  end

  def execute(message:, greeting: "Hello", context:)
    user_name = context[:user]&.name || "friend"
    "#{greeting}, #{user_name}! You said: #{message}"
  end
end
