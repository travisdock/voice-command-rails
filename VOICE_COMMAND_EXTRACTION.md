# Extract Voice Command Functionality into Standalone Gem

## Overview

Extract the voice command functionality from the Today Rails app into the `voice_command` gem skeleton, creating a simple, Rails-application-agnostic gem that allows any Rails developer to easily add voice command capabilities to their application.

**Gem Philosophy:** Keep it simple - provide the building blocks (audio processing, LLM integration, tool calling) but let developers implement their own front-end, controllers, and business logic.

## Problem Statement

The Today app has a working voice command implementation that processes audio input, communicates with LLMs using tool calling, and returns agent responses. This functionality is currently tightly coupled to the Todo domain logic. We need to extract the reusable parts into a standalone gem that other Rails applications can use.

## Proposed Solution

Create a **simple gem (Railtie only, not a full Engine)** that provides:

1. **Core processor** - Accepts audio files and returns LLM responses
2. **Multi-provider LLM support** - OpenAI, Anthropic, and Gemini
3. **Tool registration system** - DSL for developers to define custom tools
4. **Audio validation** - Configurable file size/type validation
5. **Rate limiting** - Configurable request throttling
6. **Stimulus controller** - Copied via install generator for customization
7. **Configuration DSL** - Simple setup in Rails initializer

## Technical Approach

### Architecture Decision: Simple Gem with Railtie

**Rationale:**
- No Rails-specific MVC components needed in the gem
- Developers implement their own controllers and views
- Lighter weight, easier to maintain
- Railtie provides Rails integration hooks (initializers, generators)

### Key Design Principles

1. **Dependency Injection** - No reliance on `Current.user` or other app-specific patterns
2. **Provider Agnostic** - Support multiple LLM providers through adapter pattern
3. **Configuration over Convention** - Sensible defaults, but everything configurable
4. **Generator for JavaScript** - Copy Stimulus controller to app for easy customization

### File Structure

```
voice_command/
├── lib/
│   ├── voice_command.rb                      # Main module with configure method
│   ├── voice_command/
│   │   ├── version.rb                        # VERSION = "0.1.0"
│   │   ├── railtie.rb                        # Rails integration
│   │   ├── configuration.rb                  # Configuration DSL
│   │   ├── processor.rb                      # Core audio → LLM processor
│   │   ├── tool_registry.rb                  # Tool registration system
│   │   ├── tool.rb                           # Base tool class
│   │   ├── errors.rb                         # Custom exceptions
│   │   ├── providers/
│   │   │   ├── base.rb                       # Provider interface
│   │   │   ├── openai_provider.rb
│   │   │   ├── anthropic_provider.rb
│   │   │   └── gemini_provider.rb
│   │   ├── validators/
│   │   │   ├── audio_validator.rb            # File type/size validation
│   │   │   └── rate_limiter.rb               # Request throttling
│   │   └── logging/
│   │       └── structured_logger.rb          # JSON event logging
│   ├── generators/
│   │   └── voice_command/
│   │       └── install/
│   │           ├── install_generator.rb
│   │           ├── USAGE
│   │           └── templates/
│   │               ├── initializer.rb
│   │               └── audio_recorder_controller.js
│   └── tasks/
│       └── voice_command_tasks.rake
├── app/
│   └── assets/
│       └── javascripts/
│           └── voice_command/
│               └── controllers/
│                   └── audio_recorder_controller.js
├── test/
│   ├── voice_command_test.rb
│   ├── processor_test.rb
│   ├── tool_registry_test.rb
│   ├── providers/
│   │   ├── openai_provider_test.rb
│   │   ├── anthropic_provider_test.rb
│   │   └── gemini_provider_test.rb
│   ├── validators/
│   │   ├── audio_validator_test.rb
│   │   └── rate_limiter_test.rb
│   └── dummy/                                # Test Rails app
├── voice_command.gemspec
├── Gemfile
├── Rakefile
└── README.md
```

### Implementation Phases

#### Phase 1: Core Configuration & Provider System

**Tasks:**
- [ ] Create `VoiceCommand::Configuration` class with DSL
- [ ] Implement `VoiceCommand.configure` method in main module
- [ ] Create `VoiceCommand::Providers::Base` interface
- [ ] Implement `OpenAIProvider` using `ruby-openai` gem
- [ ] Implement `AnthropicProvider` using `anthropic-sdk-ruby` gem
- [ ] Implement `GeminiProvider` using `ruby_llm` gem
- [ ] Write tests for configuration and each provider
- [ ] Update gemspec with provider gem dependencies

**Success Criteria:**
- Configuration can be set in Rails initializer
- Each provider can accept audio file path and return transcription
- Provider selection works based on configuration
- Tests pass for all three providers

**Code Example:**

```ruby
# config/initializers/voice_command.rb
VoiceCommand.configure do |config|
  config.provider = :openai
  config.openai_api_key = Rails.application.credentials.dig(:openai, :api_key)
  config.model = "gpt-4-turbo"

  # Audio validation
  config.max_file_size = 5.megabytes
  config.allowed_content_types = ['audio/webm', 'audio/mp4', 'audio/mpeg']

  # Rate limiting
  config.rate_limit_max_requests = 5
  config.rate_limit_window = 1.minute
  config.rate_limit_cache = Rails.cache

  # Logging
  config.logger = Rails.logger
end
```

#### Phase 2: Tool System & Registry

**Tasks:**
- [ ] Create `VoiceCommand::Tool` base class with parameter DSL
- [ ] Implement `VoiceCommand::ToolRegistry` for tool management
- [ ] Add `register_tool` method to configuration
- [ ] Update providers to convert tools to provider-specific format
- [ ] Write tool execution logic in processor
- [ ] Create example tools in test/dummy app
- [ ] Write comprehensive tests for tool system

**Success Criteria:**
- Developers can define tools by inheriting from `VoiceCommand::Tool`
- Tools can be registered via configuration or dynamically
- Tool parameters are validated before execution
- LLM receives tools in correct format for each provider
- Tool execution results are returned to LLM correctly

**Code Example:**

```ruby
# app/tools/create_todo_tool.rb
class CreateTodoTool < VoiceCommand::Tool
  description "Create a new todo item"

  params do
    string :title, description: "The todo item title"
    string :priority_window,
           description: "When to do it",
           enum: ["today", "tomorrow", "this_week", "next_week"],
           default: "today"
  end

  def execute(title:, priority_window: "today", context:)
    # context contains user, request metadata, etc.
    user = context[:user]
    todo = user.todos.create!(title: title, priority_window: priority_window)
    "Added '#{todo.title}' to #{priority_window}"
  end
end

# config/initializers/voice_command.rb
VoiceCommand.configure do |config|
  config.register_tool CreateTodoTool
  config.register_tool MoveTodoTool
  config.register_tool ReorderTodosTool
end
```

#### Phase 3: Core Processor

**Tasks:**
- [ ] Create `VoiceCommand::Processor` class
- [ ] Implement audio file validation
- [ ] Implement rate limiting checks
- [ ] Add provider-agnostic audio transcription
- [ ] Implement tool calling loop (LLM → tool → LLM)
- [ ] Add structured logging for all events
- [ ] Handle errors gracefully with custom exceptions
- [ ] Write processor tests with mocked providers

**Success Criteria:**
- Processor validates audio files before processing
- Rate limiting prevents abuse
- Audio is transcribed via configured provider
- Tool calls are executed and results returned to LLM
- All events are logged with structured JSON
- Errors are caught and returned with helpful messages

**Code Example:**

```ruby
# app/controllers/voice_commands_controller.rb (in Rails app)
class VoiceCommandsController < ApplicationController
  def create
    processor = VoiceCommand::Processor.new(
      audio_file: params[:audio].tempfile,
      user: current_user,  # Injected, not assumed
      context_builder: -> { build_context_for_llm },
      prompt_template: ->(context) { "Current todos:\n#{context}\n\nProcess this voice command:" }
    )

    result = processor.process

    if result.success?
      render turbo_stream: [
        turbo_stream.update("transcription", partial: "agent_response",
                           locals: { message: result.response }),
        turbo_stream.replace("todos", partial: "todos/list")
      ]
    else
      render turbo_stream: turbo_stream.update("transcription",
                                               partial: "error",
                                               locals: { error: result.error })
    end
  end

  private

  def build_context_for_llm
    service = TodoService.new(current_user.todos.active, user: current_user)
    service.list_for_context.to_json
  end
end
```

**Processor API:**

```ruby
# lib/voice_command/processor.rb
module VoiceCommand
  class Processor
    def initialize(audio_file:, user:, context_builder: nil, prompt_template: nil)
      @audio_file = audio_file
      @user = user
      @context_builder = context_builder || -> { "" }
      @prompt_template = prompt_template || ->(ctx) { ctx }
    end

    def process
      validate_audio!
      check_rate_limit!

      context = @context_builder.call
      prompt = @prompt_template.call(context)

      log_event("processing_started", audio_size: @audio_file.size)

      provider = VoiceCommand.configuration.provider_instance
      response = provider.process_audio(@audio_file.path, prompt, tools: registered_tools)

      log_event("processing_completed", response_length: response.length)

      Result.success(response: response)
    rescue RateLimitExceeded => e
      Result.failure(error: "Rate limit exceeded. Please try again later.")
    rescue AudioValidationError => e
      Result.failure(error: e.message)
    rescue StandardError => e
      log_event("processing_failed", error: e.message)
      Result.failure(error: "An error occurred processing your request.")
    end

    private

    def validate_audio!
      VoiceCommand::Validators::AudioValidator.validate!(@audio_file)
    end

    def check_rate_limit!
      VoiceCommand::Validators::RateLimiter.check!(@user)
    end

    def registered_tools
      VoiceCommand.configuration.tools.map do |tool_class|
        tool_class.new(user: @user)
      end
    end

    def log_event(event, metadata = {})
      VoiceCommand::Logging::StructuredLogger.log(event, metadata.merge(user_id: @user.id))
    end
  end
end
```

#### Phase 4: Validators

**Tasks:**
- [ ] Implement `AudioValidator` with configurable rules
- [ ] Implement `RateLimiter` using Rails.cache
- [ ] Add custom exception classes
- [ ] Write validator tests

**Success Criteria:**
- Audio files are validated for type and size
- Rate limiting works with any Rails cache backend
- Clear error messages for validation failures

**Code Example:**

```ruby
# lib/voice_command/validators/audio_validator.rb
module VoiceCommand
  module Validators
    class AudioValidator
      class << self
        def validate!(audio_file)
          config = VoiceCommand.configuration

          raise Errors::InvalidAudioFile, "No audio file provided" unless audio_file
          raise Errors::InvalidAudioFile, "Invalid file object" unless audio_file.respond_to?(:path)

          # Content type validation
          content_type = detect_content_type(audio_file)
          unless config.allowed_content_types.any? { |type| content_type.start_with?(type) }
            raise Errors::InvalidAudioFile,
                  "Invalid audio format. Allowed: #{config.allowed_content_types.join(', ')}"
          end

          # File size validation
          size = audio_file.size || File.size(audio_file.path)
          if size > config.max_file_size
            raise Errors::FileTooLarge,
                  "File size #{size} exceeds maximum #{config.max_file_size} bytes"
          end

          true
        end

        private

        def detect_content_type(file)
          # Use Marcel gem or similar for reliable MIME detection
          require 'marcel'
          Marcel::MimeType.for(file)
        end
      end
    end
  end
end

# lib/voice_command/validators/rate_limiter.rb
module VoiceCommand
  module Validators
    class RateLimiter
      class << self
        def check!(user)
          config = VoiceCommand.configuration
          return true unless user

          key = "voice_command:rate:#{user.id}"
          current = config.rate_limit_cache.increment(key, 1,
                                                       expires_in: config.rate_limit_window)

          unless current
            config.rate_limit_cache.write(key, 1, expires_in: config.rate_limit_window)
            current = 1
          end

          if current > config.rate_limit_max_requests
            raise Errors::RateLimitExceeded,
                  "Rate limit exceeded: #{config.rate_limit_max_requests} requests per #{config.rate_limit_window} seconds"
          end

          true
        end
      end
    end
  end
end
```

#### Phase 5: Install Generator & Stimulus Controller

**Tasks:**
- [ ] Extract Stimulus controller from today app
- [ ] Create install generator with templates
- [ ] Add initializer template
- [ ] Add Stimulus controller template
- [ ] Write generator usage documentation
- [ ] Add view helper documentation (developers implement their own)
- [ ] Write generator tests

**Success Criteria:**
- Running `rails generate voice_command:install` creates:
  - `config/initializers/voice_command.rb`
  - `app/javascript/controllers/voice_command_audio_recorder_controller.js`
- Generator provides clear next steps
- Developers can customize the Stimulus controller

**Generator Example:**

```ruby
# lib/generators/voice_command/install/install_generator.rb
module VoiceCommand
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Installs VoiceCommand configuration and JavaScript controller"

      def copy_initializer
        template 'initializer.rb', 'config/initializers/voice_command.rb'
      end

      def copy_stimulus_controller
        copy_file 'audio_recorder_controller.js',
                  'app/javascript/controllers/voice_command_audio_recorder_controller.js'
      end

      def add_dependencies
        gem_group :development, :test do
          gem 'dotenv-rails' unless File.read('Gemfile').include?('dotenv-rails')
        end
      end

      def show_next_steps
        say "\n" + "=" * 60
        say "VoiceCommand installed successfully!", :green
        say "=" * 60

        say "\nNext steps:"
        say "  1. Configure your LLM provider in config/initializers/voice_command.rb"
        say "  2. Add your API key to Rails credentials:"
        say "     rails credentials:edit"
        say "  3. Define your tools (see example in initializer)"
        say "  4. Create a controller action to handle audio uploads:"
        say "     rails generate controller VoiceCommands create"
        say "  5. Add the voice recorder to your view:"
        say "     <%= render 'voice_command/recorder' %>"
        say "\nDocumentation: https://github.com/yourusername/voice_command"
        say "\n" + "=" * 60
      end
    end
  end
end
```

**Stimulus Controller Template:**
```javascript
// app/javascript/controllers/voice_command_audio_recorder_controller.js
// Extracted from today app: /workspace/today/app/javascript/controllers/audio_recorder_controller.js

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="voice-command-audio-recorder"
export default class extends Controller {
  static targets = ["button", "input"]

  connect() {
    this.recording = false
    this.chunks = []
    this.detectPlatform()
  }

  disconnect() {
    this.stopRecording()
  }

  detectPlatform() {
    // iOS detection
    if (window.webkit?.messageHandlers?.startRecording) {
      this.platform = "ios"
      this.setupNativeBridge()
      return
    }

    // Android detection
    if (window.TurboNativeAudio) {
      this.platform = "android"
      this.setupNativeBridge()
      return
    }

    // Web fallback
    this.platform = "web"
  }

  setupNativeBridge() {
    // Listen for native events
    window.addEventListener("turboNative:recordingStarted", this.handleNativeStart.bind(this))
    window.addEventListener("turboNative:recordingStopped", this.handleNativeStop.bind(this))
    window.addEventListener("turboNative:recordingError", this.handleNativeError.bind(this))
  }

  toggle(event) {
    event.preventDefault()
    this.recording ? this.stopRecording() : this.startRecording()
  }

  startRecording() {
    if (this.platform === "ios") {
      window.webkit.messageHandlers.startRecording.postMessage({})
    } else if (this.platform === "android") {
      window.TurboNativeAudio.startRecording()
    } else {
      this.startWebRecording()
    }

    this.recording = true
    this.updateUI("recording")
  }

  stopRecording() {
    if (this.platform === "ios") {
      window.webkit.messageHandlers.stopRecording.postMessage({})
    } else if (this.platform === "android") {
      window.TurboNativeAudio.stopRecording()
    } else {
      this.stopWebRecording()
    }

    this.recording = false
    this.updateUI("idle")
  }

  async startWebRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })

      // Try different mime types for browser compatibility
      const mimeTypes = ['audio/webm', 'audio/mp4', 'audio/mpeg', 'audio/ogg']
      const mimeType = mimeTypes.find(type => MediaRecorder.isTypeSupported(type))

      this.mediaRecorder = new MediaRecorder(stream, { mimeType })
      this.chunks = []

      this.mediaRecorder.addEventListener('dataavailable', event => {
        if (event.data.size > 0) {
          this.chunks.push(event.data)
        }
      })

      this.mediaRecorder.addEventListener('stop', () => {
        const blob = new Blob(this.chunks, { type: mimeType })
        this.submitAudio(blob)
        stream.getTracks().forEach(track => track.stop())
      })

      this.mediaRecorder.start()
    } catch (error) {
      console.error("Failed to start recording:", error)
      alert("Could not access microphone. Please check permissions.")
      this.updateUI("idle")
    }
  }

  stopWebRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      this.mediaRecorder.stop()
    }
  }

  handleNativeStart(event) {
    this.recording = true
    this.updateUI("recording")
  }

  handleNativeStop(event) {
    // Convert base64 to blob
    const base64 = event.detail.audioData
    const binary = atob(base64)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i)
    }
    const blob = new Blob([bytes], { type: 'audio/mp4' })

    this.submitAudio(blob)
    this.recording = false
    this.updateUI("idle")
  }

  handleNativeError(event) {
    console.error("Native recording error:", event.detail)
    this.recording = false
    this.updateUI("idle")
  }

  submitAudio(blob) {
    // Create File object from blob
    const file = new File([blob], "recording.webm", { type: blob.type })

    // Create a DataTransfer object to set the file input's files
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.inputTarget.files = dataTransfer.files

    // Submit the form using Turbo
    this.element.requestSubmit()
  }

  updateUI(state) {
    if (state === "recording") {
      this.buttonTarget.classList.add("bg-red-500")
      this.buttonTarget.classList.remove("bg-slate-500")
      this.buttonTarget.disabled = false
    } else {
      this.buttonTarget.classList.remove("bg-red-500")
      this.buttonTarget.classList.add("bg-slate-500")
      this.buttonTarget.disabled = false
    }
  }
}
```

#### Phase 6: Documentation & Testing

**Tasks:**
- [ ] Write comprehensive README with:
  - Installation instructions
  - Configuration examples
  - Tool definition examples
  - Controller implementation example
  - View integration example
  - Troubleshooting guide
- [ ] Add inline code documentation (YARD)
- [ ] Write integration tests using test/dummy app
- [ ] Test with all three LLM providers
- [ ] Add CI configuration (GitHub Actions)
- [ ] Create CHANGELOG.md

**Success Criteria:**
- README covers all common use cases
- Code has YARD documentation
- Test coverage > 90%
- All tests pass on CI
- Example app in test/dummy demonstrates full integration

### Alternative Approaches Considered

**Option 1: Full Rails Engine with Controllers/Views**
- **Pros:** Batteries-included, faster initial setup
- **Cons:** Too opinionated, limits flexibility, harder to customize
- **Decision:** Rejected - Goes against "developers implement their own front-end" requirement

**Option 2: Provider-Agnostic (Bring Your Own Client)**
- **Pros:** Maximum flexibility, no LLM gem dependencies
- **Cons:** More complex setup, steeper learning curve
- **Decision:** Rejected - Too much work for developers, defeats "easy to add" goal

**Option 3: Engine for JavaScript Distribution**
- **Pros:** Automatic asset loading via asset pipeline
- **Cons:** Less flexibility, harder to customize Stimulus controller
- **Decision:** Rejected - Generator approach gives developers full control

## Acceptance Criteria

### Functional Requirements

- [ ] Gem can be installed via Gemfile
- [ ] Install generator creates initializer and Stimulus controller
- [ ] Configuration supports OpenAI, Anthropic, and Gemini providers
- [ ] Audio files are validated for type and size
- [ ] Rate limiting prevents abuse (configurable)
- [ ] Developers can define custom tools inheriting from `VoiceCommand::Tool`
- [ ] Tools are registered via configuration
- [ ] Processor accepts audio file and returns LLM response
- [ ] Tool calls are executed and results returned to LLM
- [ ] Stimulus controller handles recording in browsers and Turbo Native
- [ ] All events are logged with structured JSON

### Non-Functional Requirements

- [ ] Test coverage > 90%
- [ ] No breaking changes to existing Today app functionality
- [ ] Gem size < 500 KB
- [ ] Documentation covers all use cases
- [ ] Works with Rails 7.0+
- [ ] Compatible with Ruby 3.1+

### Quality Gates

- [ ] All tests pass (unit, integration)
- [ ] RuboCop passes with omakase config
- [ ] YARD documentation for all public methods
- [ ] README includes quick start guide
- [ ] Example implementation in test/dummy app
- [ ] Code review approval

## Success Metrics

- **Installation time**: Developer can install and configure gem in < 10 minutes
- **First voice command**: Developer can process first voice command in < 30 minutes
- **Code reuse**: 80%+ of voice command logic extracted from Today app
- **Flexibility**: Supports 3+ different domain models (todos, notes, events)

## Dependencies & Prerequisites

**Gem Dependencies:**
- Rails >= 7.0
- Stimulus >= 3.0
- `ruby-openai` (optional, for OpenAI provider)
- `anthropic-sdk-ruby` (optional, for Anthropic provider)
- `ruby_llm` (optional, for Gemini provider)
- `marcel` for MIME type detection

**Development Dependencies:**
- Minitest for testing
- RuboCop with Rails Omakase config
- YARD for documentation

**Host Application Requirements:**
- Rails 7.0+ with importmap or similar JavaScript bundler
- Stimulus installed
- Authentication system (for user context)
- Cache backend (for rate limiting)

## Risk Analysis & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| LLM provider API changes | High | Medium | Version lock dependencies, document supported versions |
| Audio format incompatibility | Medium | Low | Support multiple formats, validate with `marcel` gem |
| Rate limiting bypass | High | Low | Use atomic cache operations, add IP-based fallback |
| Tool execution failures | Medium | Medium | Wrap in try/catch, return error messages to LLM |
| Memory leaks with audio files | Medium | Low | Clean up tempfiles after processing |
| Breaking changes in Stimulus | Low | Low | Version lock Stimulus dependency |

## Resource Requirements

**Development Effort:** ~3-5 days

**Breakdown:**
- Phase 1 (Config & Providers): 1 day
- Phase 2 (Tool System): 1 day
- Phase 3 (Processor): 1 day
- Phase 4 (Validators): 0.5 days
- Phase 5 (Generator): 0.5 days
- Phase 6 (Docs & Testing): 1 day

**Infrastructure:**
- GitHub repository
- CI/CD (GitHub Actions)
- RubyGems account for publishing

## Future Considerations

### v0.2.0 - Enhanced Features
- [ ] Streaming responses for real-time feedback
- [ ] Custom prompt templates per tool
- [ ] Tool execution analytics
- [ ] Multi-language support for audio transcription

### v0.3.0 - Advanced Features
- [ ] Tool chaining (one tool triggers another)
- [ ] Conversation memory/context
- [ ] Custom audio preprocessors
- [ ] WebSocket support for live transcription

### v1.0.0 - Production Ready
- [ ] Security audit
- [ ] Performance benchmarks
- [ ] Comprehensive error recovery
- [ ] Admin dashboard for monitoring
- [ ] Optional Rails Engine with UI components

### Potential Engine Migration
If demand exists for batteries-included approach:
- Mountable routes with example endpoints
- Pre-built view components
- Admin interface for tool management
- Built-in analytics

## Documentation Plan

### README Sections
1. **Installation** - Gemfile, bundle install, generator
2. **Quick Start** - 5-minute working example
3. **Configuration** - All config options explained
4. **Tool Definition** - Creating custom tools
5. **Controller Integration** - Example Rails controller
6. **View Integration** - HTML/ERB examples
7. **Stimulus Controller** - Customization guide
8. **Testing** - How to test tools and integrations
9. **Troubleshooting** - Common issues and solutions
10. **API Reference** - Link to YARD docs

### Inline Documentation
- YARD comments for all public classes and methods
- Usage examples in module-level documentation
- Type signatures for method parameters

### Wiki/Guides
- Provider setup guides (OpenAI, Anthropic, Gemini)
- Multi-tenancy implementation guide
- Turbo Native integration guide
- Performance optimization tips

## References & Research

### Internal References (Today App)
- **Stimulus Controller**: `/workspace/today/app/javascript/controllers/audio_recorder_controller.js:1-299`
- **Voice Processor**: `/workspace/today/app/services/voice_command_processor.rb:1-157`
- **AgentsController**: `/workspace/today/app/controllers/agents_controller.rb:1-107`
- **Tool Examples**:
  - CreateTodoTool: `/workspace/today/app/tools/create_todo_tool.rb:1-29`
  - MoveTodoTool: `/workspace/today/app/tools/move_todo_tool.rb:1-20`
  - ReorderTodosTool: `/workspace/today/app/tools/reorder_todos_tool.rb:1-20`
- **Configuration**: `/workspace/today/config/initializers/ruby_llm.rb:1-3`

### External References

**Framework Documentation:**
- Rails Engines Guide: https://guides.rubyonrails.org/engines.html
- Rails Generators Guide: https://guides.rubyonrails.org/generators.html
- importmap-rails: https://github.com/rails/importmap-rails
- Stimulus Handbook: https://stimulus.hotwired.dev/handbook/installing
- Stimulus Reference: https://stimulus.hotwired.dev/reference/controllers

**LLM Integration:**
- OpenAI Ruby SDK: https://github.com/openai/openai-ruby
- ruby-openai: https://github.com/alexrudall/ruby-openai
- Anthropic SDK: https://github.com/anthropics/anthropic-sdk-ruby
- OpenAI API Docs: https://platform.openai.com/docs/
- Anthropic API Docs: https://docs.anthropic.com/

**Best Practices:**
- stimulus-rails patterns: https://github.com/hotwired/stimulus-rails
- turbo-rails JavaScript distribution: https://github.com/hotwired/turbo-rails
- rails_admin gem structure (for generator patterns)

### Related Work
- **ruby_llm gem**: Multi-provider LLM integration (used in Today app)
- **langchainrb**: Rails LLM toolkit (more complex, different approach)
- **openai-ruby**: Official OpenAI SDK

---

**Ready for Implementation:** This issue provides a complete blueprint for extracting voice command functionality into a standalone, reusable Rails gem while maintaining simplicity and flexibility.
