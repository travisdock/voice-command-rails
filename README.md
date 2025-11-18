# VoiceCommand

VoiceCommand is a lightweight bridge between browser-based audio capture and RubyLLM. It gives you a Stimulus-powered recorder plus a backend gateway that validates audio uploads, forwards them to Gemini Flash (configurable), and returns the agent's text response. Front-end rendering, controller actions, and tool definitions remain entirely under your control.

## Installation

Add the gem to your Rails application:

```ruby
gem "voice_command", path: "../voice_command" # adjust as needed
```

Run bundle install and then (optionally) copy the audio recorder Stimulus controller:

```bash
bin/rails generate voice_command:install
```

Use `--skip-stimulus` to opt out of copying the JavaScript file if you prefer to write your own implementation.

## Configuration

Configure the gem (usually inside `config/initializers/voice_command.rb`):

```ruby
VoiceCommand.configure do |config|
  config.audio_max_bytes = 5.megabytes
  config.allowed_content_types = ["audio/"] # accepts strings, regexes, or callables

  # RubyLLM chat builder (Gemini Flash by default)
  config.llm_model = "gemini-2.0-flash"
  config.chat_factory = ->(model:, **) { RubyLLM.chat(model: model) }

  # Provide tools to the chat client. This receives the controller context you pass
  # to VoiceCommand.process so you can look up the current user, etc.
  config.tool_provider = ->(context) { VoiceAgent::Toolbox.build(context[:user]) }
end
```

You can override any setting at call-time as well (see below).

## Controller usage

The gem focuses on the controller entry-point. Pass it an uploaded audio file, your prompt, and whatever context you need to hydrate tools or build prompts.

```ruby
class VoiceAgentsController < ApplicationController
  def create
    result = VoiceCommand.process(
      audio: params[:audio],                   # ActionDispatch::Http::UploadedFile
      prompt: VoiceAgentPrompt.new(Current.user).render,
      context: { user: Current.user }          # forwarded to your tool provider
    )

    if result[:success]
      render json: { message: result[:message] }
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end
end
```

`VoiceCommand.process` handles the audio validations, logs timing information, adds the configured tools to your RubyLLM chat client, and returns a response hash with:

```ruby
{
  success: true/false,
  message: "LLM response text",
  raw_response: #<RubyLLM::Message ...>,
  metadata: { api_duration_ms: 123, total_duration_ms: 456, audio_size_bytes: 789 }
}
```

## View helper and Stimulus controller

When you run `voice_command:install` we copy `audio_recorder_controller.js` into `app/javascript/controllers`. Import it via your Stimulus loader (`import "controllers"` / `import "./audio_recorder_controller"` depending on your setup).

To drop a ready-to-record form into a view, call the helper:

```erb
<%= voice_command_recorder_form(endpoint: voice_agents_path) do |form| %>
  <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
<% end %>
```

- The helper renders a file input tied to the Stimulus controller, a record button, and a status element you can target in your responses.
- Customize classes and attributes through `form_options:`, `button_html:`, and `status_html:`.
- If you prefer to build your own UI, skip the helper and wire the Stimulus controller to your markup manually.

## Tooling expectations

The gem doesn't ship any tools. Provide your own RubyLLM tool classes and expose them through the configured `tool_provider`. Because this is just a plain callable, you can return different tools per user, per prompt, or per controller action:

```ruby
VoiceCommand.configure do |config|
  config.tool_provider = lambda do |context|
    [
      Todos::CreateTool.new(context[:user]),
      Todos::ReorderTool.new(context[:user])
    ]
  end
end
```

### Per-controller overrides

You can override the tool list (or the model/chat options) for any individual controller action. Pass a different `tool_provider` lambda to `VoiceCommand.process` and use the `context` hash to expose anything the lambda needs:

```ruby
class VoiceAgentsController < ApplicationController
  def reorder
    result = VoiceCommand.process(
      audio: params[:audio],
      prompt: prompts.reorder,
      context: { user: Current.user, window: params[:window] },
      tool_provider: ->(ctx) { [Todos::ReorderTool.new(ctx[:user], ctx[:window])] }
    )

    render json: { message: result[:message] }
  end

  private

  def prompts
    VoiceAgentPrompt.new(Current.user)
  end
end
```

If every action uses the global configuration, skip the override and rely on `VoiceCommand.config.tool_provider`.

## Contributing

1. `cd voice_command && bundle exec rake test` to run the suite.
2. Send PRs with tests and documentation.

## License

MIT. See [MIT-LICENSE](MIT-LICENSE).
