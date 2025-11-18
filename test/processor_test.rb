require "test_helper"
require "tempfile"

class VoiceCommand::ProcessorTest < ActiveSupport::TestCase
  class MockUser
    attr_reader :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end
  end

  # Mock provider for testing
  class MockProvider < VoiceCommand::Providers::Base
    attr_reader :last_prompt, :last_tools, :last_context

    def process_audio(audio_file_path, prompt, tools: [], context: {})
      @last_prompt = prompt
      @last_tools = tools
      @last_context = context
      "Mock response: processed #{File.basename(audio_file_path)}"
    end
  end

  setup do
    VoiceCommand.reset_configuration!
    @user = MockUser.new(1, "Alice")
    @audio_file = create_temp_audio_file
  end

  teardown do
    @audio_file&.close
    @audio_file&.unlink
    VoiceCommand::Validators::RateLimiter.reset!(@user)
  end

  test "initializes with required parameters" do
    processor = VoiceCommand::Processor.new(
      audio_file: @audio_file,
      user: @user
    end

    assert_equal @audio_file, processor.audio_file
    assert_equal @user, processor.user
  end

  test "initializes with optional context builder and prompt template" do
    context_builder = -> { "custom context" }
    prompt_template = ->(ctx) { "Prompt: #{ctx}" }

    processor = VoiceCommand::Processor.new(
      audio_file: @audio_file,
      user: @user,
      context_builder: context_builder,
      prompt_template: prompt_template
    )

    assert_equal context_builder, processor.context_builder
    assert_equal prompt_template, processor.prompt_template
  end

  test "process returns success result with valid input" do
    # Configure with mock provider
    mock_provider = MockProvider.new(VoiceCommand.configuration)
    VoiceCommand::Configuration.any_instance.stubs(:provider_instance).returns(mock_provider)

    processor = VoiceCommand::Processor.new(
      audio_file: @audio_file,
      user: @user
    )

    result = processor.process

    assert result.success?
    assert_includes result.response, "Mock response"
    assert_nil result.error
  end

  test "process returns failure result when audio validation fails" do
    # Create invalid file (too large)
    VoiceCommand.configure do |config|
      config.max_file_size = 100 # Very small limit
    end

    processor = VoiceCommand::Processor.new(
      audio_file: @audio_file,
      user: @user
    )

    result = processor.process

    assert result.failure?
    assert_includes result.error, "File size"
    assert_nil result.response
  end

  test "process returns failure result when rate limit exceeded" do
    VoiceCommand.configure do |config|
      config.rate_limit_max_requests = 1
    end

    # Use up the limit
    VoiceCommand::Validators::RateLimiter.check!(@user)

    processor = VoiceCommand::Processor.new(
      audio_file: @audio_file,
      user: @user
    )

    result = processor.process

    assert result.failure?
    assert_includes result.error, "Rate limit exceeded"
    assert_nil result.response
  end

  test "process uses context builder to build context" do
    mock_provider = MockProvider.new(VoiceCommand.configuration)
    VoiceCommand::Configuration.any_instance.stubs(:provider_instance).returns(mock_provider)

    context_builder = -> { { todos: [ "Buy milk", "Walk dog" ] } }

    processor = VoiceCommand::Processor.new(
      audio_file: @audio_file,
      user: @user,
      context_builder: context_builder
    )

    processor.process

    # The context builder output should be used
    assert_not_nil mock_provider.last_prompt
  end

  test "process uses prompt template" do
    mock_provider = MockProvider.new(VoiceCommand.configuration)
    VoiceCommand::Configuration.any_instance.stubs(:provider_instance).returns(mock_provider)

    context_builder = -> { "Task list: Buy milk" }
    prompt_template = ->(ctx) { "System: #{ctx}\n\nProcess this command:" }

    processor = VoiceCommand::Processor.new(
      audio_file: @audio_file,
      user: @user,
      context_builder: context_builder,
      prompt_template: prompt_template
    )

    processor.process

    assert_includes mock_provider.last_prompt, "System: Task list: Buy milk"
    assert_includes mock_provider.last_prompt, "Process this command:"
  end

  test "process passes tools from configuration to provider" do
    mock_provider = MockProvider.new(VoiceCommand.configuration)
    VoiceCommand::Configuration.any_instance.stubs(:provider_instance).returns(mock_provider)

    tool_class = Class.new(VoiceCommand::Tool)
    VoiceCommand.configure do |config|
      config.register_tool(tool_class)
    end

    processor = VoiceCommand::Processor.new(
      audio_file: @audio_file,
      user: @user
    )

    processor.process

    assert_equal [ tool_class ], mock_provider.last_tools
  end

  test "process passes user in context to provider" do
    mock_provider = MockProvider.new(VoiceCommand.configuration)
    VoiceCommand::Configuration.any_instance.stubs(:provider_instance).returns(mock_provider)

    processor = VoiceCommand::Processor.new(
      audio_file: @audio_file,
      user: @user
    )

    processor.process

    assert_equal @user, mock_provider.last_context[:user]
    assert_not_nil mock_provider.last_context[:timestamp]
  end

  private

  def create_temp_audio_file
    file = Tempfile.new([ "test_audio", ".mp3" ])
    file.write("fake audio data " * 10)
    file.rewind
    file
  end
end
