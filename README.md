# VoiceCommand 🎤

A simple Rails gem that adds voice command capabilities to your Rails application with LLM integration. Process audio input, execute custom tools, and return natural language responses.

## Features

- 🎙️ **Audio Processing** - Handles audio file validation and transcription
- 🤖 **Multi-Provider LLM Support** - Works with OpenAI, Anthropic (Claude), and Google Gemini
- 🛠️ **Custom Tool System** - Define tools that the LLM can call to perform actions
- ⚡ **Rate Limiting** - Built-in request throttling per user
- 📱 **Turbo Native Support** - Works seamlessly with iOS and Android via Turbo Native bridges
- 🎯 **Simple API** - Minimal configuration, maximum flexibility
- ✅ **Fully Tested** - Comprehensive test coverage

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'voice_command'
```

Then execute:

```bash
bundle install
rails generate voice_command:install
```

This will create:
- `config/initializers/voice_command.rb` - Configuration file
- `app/javascript/controllers/voice_command_audio_recorder_controller.js` - Stimulus controller

## Quick Start (5 Minutes)

### 1. Configure Your LLM Provider

Edit `config/initializers/voice_command.rb`:

```ruby
VoiceCommand.configure do |config|
  config.provider = :openai  # or :anthropic, :gemini
  config.openai_api_key = Rails.application.credentials.dig(:openai, :api_key)
  config.model = "gpt-4-turbo"
end
```

### 2. Add API Key to Credentials

```bash
rails credentials:edit
```

Add your API key:

```yaml
openai:
  api_key: sk-your-api-key-here
```

### 3. Define Your Tools

Create `app/tools/create_task_tool.rb`:

```ruby
class CreateTaskTool < VoiceCommand::Tool
  description "Create a new task with a title"

  params do
    string :title, description: "The task title"
    string :priority, enum: ["low", "medium", "high"], default: "medium"
  end

  def execute(title:, priority: "medium", context:)
    user = context[:user]
    task = user.tasks.create!(title: title, priority: priority)
    "Created task: #{task.title}"
  end
end
```

### 4. Register Your Tools

In `config/initializers/voice_command.rb`:

```ruby
VoiceCommand.configure do |config|
  # ... other config ...
  config.register_tool(CreateTaskTool)
end
```

### 5. Create a Controller

```bash
rails generate controller VoiceCommands create
```

Edit `app/controllers/voice_commands_controller.rb`:

```ruby
class VoiceCommandsController < ApplicationController
  def create
    processor = VoiceCommand::Processor.new(
      audio_file: params[:audio].tempfile,
      user: current_user,
      context_builder: -> { build_context },
      prompt_template: ->(ctx) { "Current tasks: #{ctx}\n\nProcess this command:" }
    )

    result = processor.process

    if result.success?
      render turbo_stream: turbo_stream.update("response", result.response)
    else
      render turbo_stream: turbo_stream.update("error", result.error),
             status: :unprocessable_entity
    end
  end

  private

  def build_context
    current_user.tasks.pluck(:title).to_json
  end
end
```

### 6. Add the Voice Recorder to Your View

```erb
<!-- app/views/tasks/index.html.erb -->
<div id="response"></div>

<%= form_with url: voice_commands_path,
              method: :post,
              multipart: true,
              html: {
                data: { controller: "voice-command-audio-recorder" }
              } do |f| %>
  <%= f.file_field :audio,
                   accept: "audio/webm,audio/mp4,audio/mpeg",
                   data: { voice_command_audio_recorder_target: "input" },
                   class: "hidden" %>

  <button type="button"
          data-action="voice-command-audio-recorder#toggle"
          data-voice-command-audio-recorder-target="button"
          class="bg-blue-500 hover:bg-blue-600 text-white rounded-full p-4">
    🎤 Record
  </button>
<% end %>
```

### 7. Add Route

```ruby
# config/routes.rb
post '/voice_commands', to: 'voice_commands#create'
```

Done! 🎉 Try saying "Create a task called buy milk"

## Configuration

### Provider Options

**OpenAI:**
```ruby
config.provider = :openai
config.openai_api_key = ENV['OPENAI_API_KEY']
config.model = "gpt-4-turbo"
```

**Anthropic (Claude):**
```ruby
config.provider = :anthropic
config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
config.model = "claude-sonnet-4-5-20250929"
```

**Google Gemini:**
```ruby
config.provider = :gemini
config.gemini_api_key = ENV['GEMINI_API_KEY']
config.model = "gemini-2.0-flash"
```

### Audio Validation

```ruby
config.max_file_size = 5.megabytes
config.allowed_content_types = [
  "audio/webm",
  "audio/mp4",
  "audio/mpeg",
  "audio/m4a",
  "audio/ogg"
]
```

### Rate Limiting

```ruby
config.rate_limit_max_requests = 5      # Max requests
config.rate_limit_window = 1.minute     # Per window
config.rate_limit_cache = Rails.cache   # Cache backend
```

## Tool Definition Guide

### Basic Tool

```ruby
class MyTool < VoiceCommand::Tool
  description "What this tool does"

  params do
    string :name
    integer :age
    boolean :active, default: true
  end

  def execute(name:, age:, active: true, context:)
    # Your logic here
    user = context[:user]
    # Return natural language response
    "Done!"
  end
end
```

### Parameter Types

```ruby
params do
  # String parameter
  string :title, description: "Task title"

  # String with enum
  string :priority, enum: ["low", "medium", "high"], default: "medium"

  # Integer with constraints
  integer :count, minimum: 1, maximum: 100

  # Boolean
  boolean :active, default: true

  # Array
  array :tags, items: { type: "string" }
end
```

### Accessing Context

The `context` hash contains:
- `:user` - The user making the request
- `:timestamp` - When the request was made
- Any custom data you add in your `context_builder`

## Examples

See the `test/dummy` app for a complete working example.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
