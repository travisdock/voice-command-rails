# VoiceCommand Configuration
# For more information, see: https://github.com/yourusername/voice_command

VoiceCommand.configure do |config|
  # ============================================================================
  # LLM Provider Configuration
  # ============================================================================
  # Choose your provider: :openai, :anthropic, or :gemini
  config.provider = :openai

  # Provider-specific API keys (store these in Rails credentials, not here!)
  config.openai_api_key = Rails.application.credentials.dig(:openai, :api_key)
  # config.anthropic_api_key = Rails.application.credentials.dig(:anthropic, :api_key)
  # config.gemini_api_key = Rails.application.credentials.dig(:gemini, :api_key)

  # Model to use (provider-specific)
  config.model = "gpt-4-turbo"
  # config.model = "claude-sonnet-4-5-20250929"  # For Anthropic
  # config.model = "gemini-2.0-flash"            # For Gemini

  # ============================================================================
  # Audio Validation Settings
  # ============================================================================
  config.max_file_size = 5.megabytes
  config.allowed_content_types = [
    "audio/webm",
    "audio/mp4",
    "audio/mpeg",
    "audio/m4a",
    "audio/ogg"
  ]

  # ============================================================================
  # Rate Limiting Settings
  # ============================================================================
  config.rate_limit_max_requests = 5
  config.rate_limit_window = 1.minute
  config.rate_limit_cache = Rails.cache

  # ============================================================================
  # Logging
  # ============================================================================
  config.logger = Rails.logger

  # ============================================================================
  # Register Your Tools
  # ============================================================================
  # Example tool registration (create these in app/tools/)
  # config.register_tool(CreateTaskTool)
  # config.register_tool(UpdateTaskTool)
  # config.register_tool(DeleteTaskTool)
end

# ============================================================================
# Example Tool Definition (create in app/tools/create_task_tool.rb)
# ============================================================================
=begin
class CreateTaskTool < VoiceCommand::Tool
  description "Create a new task with a title and optional priority"

  params do
    string :title, description: "The task title"
    string :priority,
           description: "Task priority level",
           enum: ["low", "medium", "high"],
           default: "medium"
  end

  def execute(title:, priority: "medium", context:)
    user = context[:user]
    task = user.tasks.create!(title: title, priority: priority)
    "Created task: #{task.title} (#{task.priority} priority)"
  end
end
=end

# ============================================================================
# Example Controller Implementation
# ============================================================================
=begin
# app/controllers/voice_commands_controller.rb
class VoiceCommandsController < ApplicationController
  def create
    processor = VoiceCommand::Processor.new(
      audio_file: params[:audio].tempfile,
      user: current_user,
      context_builder: -> { build_context_for_llm },
      prompt_template: ->(context) { build_prompt(context) }
    )

    result = processor.process

    if result.success?
      render turbo_stream: turbo_stream.update(
        "transcription",
        partial: "voice_commands/response",
        locals: { message: result.response }
      )
    else
      render turbo_stream: turbo_stream.update(
        "transcription",
        partial: "voice_commands/error",
        locals: { error: result.error }
      ), status: :unprocessable_entity
    end
  end

  private

  def build_context_for_llm
    {
      tasks: current_user.tasks.pluck(:id, :title, :status),
      current_time: Time.current
    }
  end

  def build_prompt(context)
    <<~PROMPT
      You are a helpful assistant that manages tasks.

      Current tasks:
      #{context[:tasks].to_json}

      Process the user's voice command and use the available tools to help them.
      Always respond with a natural confirmation of what you did.
    PROMPT
  end
end
=end

# ============================================================================
# Example View Integration
# ============================================================================
=begin
<!-- app/views/tasks/index.html.erb -->
<div id="transcription" class="mb-4"></div>

<%= form_with url: voice_commands_path,
              method: :post,
              multipart: true,
              html: {
                class: "fixed bottom-4 right-4 z-50",
                data: { controller: "voice-command-audio-recorder" }
              } do |f| %>
  <%= f.file_field :audio,
                   accept: "audio/webm,audio/mp4,audio/mpeg",
                   data: { voice_command_audio_recorder_target: "input" },
                   class: "hidden" %>

  <button type="button"
          data-action="voice-command-audio-recorder#toggle"
          data-voice-command-audio-recorder-target="button"
          class="bg-blue-500 hover:bg-blue-600 text-white rounded-full p-4 shadow-lg">
    <!-- Microphone icon -->
    <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
      <path d="M7 4a3 3 0 016 0v6a3 3 0 11-6 0V4z"/>
      <path d="M5.5 9.643a.75.75 0 00-1.5 0V10c0 3.06 2.29 5.585 5.25 5.954V17.5h-1.5a.75.75 0 000 1.5h4.5a.75.75 0 000-1.5h-1.5v-1.546A6.001 6.001 0 0016 10v-.357a.75.75 0 00-1.5 0V10a4.5 4.5 0 01-9 0v-.357z"/>
    </svg>
  </button>
<% end %>
=end
