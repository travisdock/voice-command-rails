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

### 4. Styling (Optional)

The gem includes minimal, framework-agnostic CSS that works out of the box. You have several options for styling:

#### Option 1: Use the Default Styles (Easiest)

The gem automatically includes a basic stylesheet. No additional configuration needed!

```ruby
# config/initializers/voice_command_rails.rb
VoiceCommandRails.configure do |config|
  # Use defaults - nothing to configure!
end
```

#### Option 2: Add Custom Classes (Recommended for Framework Users)

Inject your framework's utility classes without overriding:

```ruby
# config/initializers/voice_command_rails.rb
VoiceCommandRails.configure do |config|
  config.custom_button_class = "btn btn-primary shadow-lg"  # Bootstrap
  # or
  config.custom_button_class = "bg-blue-600 hover:bg-blue-700 text-white"  # Tailwind

  config.custom_container_class = "my-custom-container"
  config.custom_message_class = "card"
end
```

The custom classes are **added to** (not replacing) the base classes, so the gem's functionality still works.

#### Option 3: Override CSS Styles

Override the default styles in your application's stylesheet:

```css
/* app/assets/stylesheets/application.css */

/* Customize the button - target by class */
.voice-command-button {
  background-color: #your-brand-color;
  width: 64px;
  height: 64px;
}

/* Or target by data attribute */
[data-voice-command-microphone] {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  width: 70px;
  height: 70px;
}

/* Customize messages */
.voice-command-message {
  border-radius: 1rem;
  box-shadow: your-shadow;
  background: #f8f9fa;
}

/* Customize positioning */
.voice-command-position-bottom-right {
  bottom: 2rem;
  right: 2rem;
}

/* Dark mode override */
@media (prefers-color-scheme: dark) {
  .voice-command-button {
    background-color: #your-dark-brand-color;
  }
}
```

#### Option 4: Use with Tailwind CSS (@apply)

Use Tailwind's `@apply` directive in your CSS:

```css
/* app/assets/stylesheets/application.css */

.voice-command-button {
  @apply bg-blue-600 hover:bg-blue-700 active:bg-blue-800;
  @apply text-white rounded-full;
  @apply w-16 h-16;
  @apply shadow-lg hover:shadow-xl;
  @apply transition-all duration-200;
  @apply focus:ring-4 focus:ring-blue-300;
}

.voice-command-message {
  @apply bg-white dark:bg-gray-800;
  @apply rounded-lg shadow-md;
  @apply border border-gray-200 dark:border-gray-700;
}
```

#### Option 5: Completely Custom Styling

Disable the gem's stylesheet and write everything from scratch:

1. Remove the gem's stylesheet from your asset pipeline:

```ruby
# app/assets/config/manifest.js
// Remove or comment out:
// link voice_command_rails_application.css
```

2. Create your own styles targeting the semantic class names:

```css
/* app/assets/stylesheets/voice_commands.css */

/* Container */
.voice-command-container {
  /* Your positioning and layout */
}

/* Button */
.voice-command-button {
  /* Completely custom button styles */
}

/* Messages */
.voice-command-message {
  /* Completely custom message styles */
}

/* See full list of classes below */
```

**Available CSS Classes:**
- `.voice-command-container` - Main container
- `.voice-command-button` - Microphone button (also has `[data-voice-command-microphone]`)
- `.voice-command-icon` - SVG icon inside button
- `.voice-command-status` - Status message
- `.voice-command-message` - Message card (also has `[data-voice-command-message]`)
- `.voice-command-message-success` - Success modifier
- `.voice-command-message-error` - Error modifier
- `.voice-command-message-title` - Message title
- `.voice-command-message-text` - Message body
- `.voice-command-message-timestamp` - Timestamp

**Available Data Attributes (for easier targeting):**
- `[data-voice-command-button]` - Container element
- `[data-voice-command-microphone]` - Button element
- `[data-voice-command-message="success"]` - Success message
- `[data-voice-command-message="error"]` - Error message

#### Examples of Complete Customizations

**Bootstrap Example:**

```ruby
# config/initializers/voice_command_rails.rb
config.custom_button_class = "btn btn-primary btn-lg rounded-circle"
config.custom_message_class = "alert"
```

```css
/* app/assets/stylesheets/application.css */
.voice-command-message-success {
  @extend .alert-success;
}

.voice-command-message-error {
  @extend .alert-danger;
}
```

**Tailwind Example:**

```ruby
# config/initializers/voice_command_rails.rb
config.custom_button_class = "bg-indigo-600 hover:bg-indigo-700 ring-2 ring-indigo-400"
config.custom_container_class = "bottom-20 right-20"
```

**Material Design Example:**

```css
.voice-command-button {
  background: #6200ea;
  box-shadow: 0 3px 5px -1px rgba(0,0,0,.2), 0 6px 10px 0 rgba(0,0,0,.14);
  transition: box-shadow 280ms cubic-bezier(0.4, 0, 0.2, 1);
}

.voice-command-button:hover {
  box-shadow: 0 5px 5px -3px rgba(0,0,0,.2), 0 8px 10px 1px rgba(0,0,0,.14);
}
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
