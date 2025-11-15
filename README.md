# VoiceCommandRails

Add AI-powered voice commands to your Rails application with minimal configuration. This gem handles audio recording (JavaScript), transcription via Gemini Flash, and tool/function calling—all through a clean, Rails-conventional API.

## Features

- **JavaScript Audio Recording**: Stimulus controller with progressive enhancement (Web Audio API, iOS/Android native bridges)
- **AI Transcription**: Powered by Gemini Flash via the ruby_llm gem
- **Tool Calling**: Simple DSL for defining voice-callable tools
- **Real-time UI Updates**: Turbo Streams integration
- **Rails Conventions**: Follows Rails patterns and best practices
- **Secure by Default**: Built-in rate limiting, file validation, and CSRF protection

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'voice_command_rails'
```

And then execute:

```bash
bundle install
```

Run the install generator:

```bash
rails generate voice_command_rails:install
```

## Configuration

The install generator creates an initializer at `config/initializers/voice_command_rails.rb`:

```ruby
VoiceCommandRails.configure do |config|
  # AI Configuration
  config.model = 'gemini-2.5-flash'               # AI model to use
  config.temperature = 0.3                         # Response creativity (0.0-1.0)
  config.system_prompt = "You are a helpful..."    # Base instructions for AI

  # Context Building - provide data to the AI
  config.context_builder = ->(user:) {
    {
      tasks: user.tasks.active.pluck(:id, :title, :due_date).map do |id, title, due_date|
        { id: id, title: title, due_date: due_date }
      end
    }
  }

  # File Upload Settings
  config.max_file_size = 5.megabytes               # Maximum audio file size
  config.allowed_mime_types = %w[audio/webm audio/mp4 audio/mpeg audio/wav]

  # Rate Limiting
  config.rate_limit_enabled = true
  config.rate_limit_max = 5                        # Requests per window
  config.rate_limit_window = 1.minute

  # UI Settings
  config.button_position = :bottom_right           # :bottom_right, :bottom_left, :custom
  config.enable_auto_fade = true                   # Auto-hide response messages
  config.fade_delay = 5.seconds

  # Feature Flags
  config.feature_flag_method = :voice_commands_enabled?  # Method to check on User

  # Logging
  config.log_transcriptions = Rails.env.development?
  config.log_tool_calls = true
end
```

### Configure RubyLLM

Add your Gemini API key to Rails credentials:

```bash
EDITOR=vim rails credentials:edit
```

Add:

```yaml
gemini_api_key: your_api_key_here
```

Then configure ruby_llm in an initializer (`config/initializers/ruby_llm.rb`):

```ruby
RubyLLM.configure do |config|
  config.gemini_api_key = Rails.application.credentials.gemini_api_key
end
```

## Usage

### 1. Define Tools

Create tools in `app/voice_tools/` directory:

```ruby
# app/voice_tools/create_task_tool.rb
class CreateTaskTool < VoiceCommandRails::Tool
  description "Create a new task with a title and optional due date"

  params do
    string :title, description: "The task title"
    any_of :due_date, description: "Due date (e.g., 'tomorrow', '2024-12-25')" do
      string
      null
    end
    any_of :priority, description: "Priority level" do
      string enum: %w[low medium high]
      null
    end
  end

  def execute(title:, due_date: nil, priority: 'medium')
    task = Current.user.tasks.create!(
      title: title,
      due_date: parse_date(due_date),
      priority: priority
    )

    "Created task: #{task.title}" + (task.due_date ? " (due #{task.due_date.to_s(:long)})" : "")
  end

  private

  def parse_date(date_str)
    return nil if date_str.blank?
    Chronic.parse(date_str)&.to_date || Date.parse(date_str)
  rescue Date::Error
    nil
  end
end
```

#### Simplified Parameter Definition

For simple tools, you can use the `param` helper:

```ruby
class SimpleToolExample < VoiceCommandRails::Tool
  description "A simple example tool"

  # Required string parameter
  param :name, desc: "User's name"

  # Optional parameter with enum
  param :status, desc: "Status", enum: %w[active inactive], required: false

  # Integer parameter
  param :count, type: :integer, desc: "Number of items"

  def execute(name:, status: 'active', count:)
    # Implementation
  end
end
```

### 2. Add Voice Button to Your Views

```erb
<!-- app/views/layouts/application.html.erb -->
<%= render 'voice_command_rails/audio_button' if current_user&.voice_commands_enabled? %>
```

### 3. Enable Feature Flag

Add a migration to enable the feature flag:

```bash
rails generate migration AddVoiceCommandsEnabledToUsers voice_commands_enabled:boolean
rails db:migrate
```

Set the flag for users who should have access:

```ruby
current_user.update!(voice_commands_enabled: true)
```

## How It Works

1. **User clicks the microphone button** - JavaScript starts recording audio
2. **Recording stops** - Audio file is uploaded to your Rails app
3. **Audio is transcribed** - Gemini Flash converts speech to text
4. **AI analyzes the command** - Determines which tool(s) to call
5. **Tools execute** - Your defined tools perform actions (create tasks, etc.)
6. **Response displays** - User sees confirmation via Turbo Stream

## Development Roadmap

### Phase 1: Core Infrastructure ✅
- [x] Rails Engine setup
- [x] Configuration system
- [x] Tool base class
- [x] Error classes

### Phase 2: Services & Controllers (In Progress)
- [ ] CommandProcessor service
- [ ] ToolRegistry service
- [ ] CommandsController
- [ ] Audio validation

### Phase 3: JavaScript & UI
- [ ] Audio recorder Stimulus controller
- [ ] Response display controller
- [ ] View partials
- [ ] CSS styling

### Phase 4: Generators
- [ ] Install generator
- [ ] Tool generator
- [ ] Migration generator

### Phase 5: Testing & Documentation
- [ ] RSpec setup
- [ ] System tests
- [ ] API documentation
- [ ] Example application

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/voice_command_rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

This gem is inspired by the voice command implementation in the [Today app](https://github.com/travisdock/today) and built on top of the excellent [ruby_llm](https://github.com/crmne/ruby_llm) gem.
