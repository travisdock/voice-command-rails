require "test_helper"

class VoiceCommand::ConfigurationTest < ActiveSupport::TestCase
  setup do
    VoiceCommand.reset_configuration!
  end

  test "has default configuration values" do
    config = VoiceCommand.configuration

    assert_equal :openai, config.provider
    assert_equal "gpt-4-turbo", config.model
    assert_equal 5 * 1024 * 1024, config.max_file_size
    assert_equal [ "audio/webm", "audio/mp4", "audio/mpeg", "audio/m4a", "audio/ogg" ], config.allowed_content_types
    assert_equal 5, config.rate_limit_max_requests
    assert_equal 60, config.rate_limit_window
    assert_empty config.tools
  end

  test "can configure provider settings" do
    VoiceCommand.configure do |config|
      config.provider = :anthropic
      config.model = "claude-sonnet-4-5-20250929"
      config.anthropic_api_key = "test_key"
    end

    config = VoiceCommand.configuration
    assert_equal :anthropic, config.provider
    assert_equal "claude-sonnet-4-5-20250929", config.model
    assert_equal "test_key", config.anthropic_api_key
  end

  test "can configure audio validation settings" do
    VoiceCommand.configure do |config|
      config.max_file_size = 10.megabytes
      config.allowed_content_types = [ "audio/mp3" ]
    end

    config = VoiceCommand.configuration
    assert_equal 10.megabytes, config.max_file_size
    assert_equal [ "audio/mp3" ], config.allowed_content_types
  end

  test "can configure rate limiting settings" do
    cache = ActiveSupport::Cache::MemoryStore.new

    VoiceCommand.configure do |config|
      config.rate_limit_max_requests = 10
      config.rate_limit_window = 120
      config.rate_limit_cache = cache
    end

    config = VoiceCommand.configuration
    assert_equal 10, config.rate_limit_max_requests
    assert_equal 120, config.rate_limit_window
    assert_equal cache, config.rate_limit_cache
  end

  test "can register tools" do
    tool_class = Class.new

    VoiceCommand.configure do |config|
      config.register_tool(tool_class)
    end

    config = VoiceCommand.configuration
    assert_includes config.tools, tool_class
  end

  test "does not register duplicate tools" do
    tool_class = Class.new

    VoiceCommand.configure do |config|
      config.register_tool(tool_class)
      config.register_tool(tool_class)
    end

    config = VoiceCommand.configuration
    assert_equal 1, config.tools.count(tool_class)
  end

  test "reset_configuration! restores defaults" do
    VoiceCommand.configure do |config|
      config.provider = :gemini
      config.model = "custom-model"
    end

    VoiceCommand.reset_configuration!
    config = VoiceCommand.configuration

    assert_equal :openai, config.provider
    assert_equal "gpt-4-turbo", config.model
  end

  test "provider_instance returns correct provider for openai" do
    VoiceCommand.configure do |config|
      config.provider = :openai
      config.openai_api_key = "test_key"
    end

    provider = VoiceCommand.configuration.provider_instance
    assert_instance_of VoiceCommand::Providers::OpenAIProvider, provider
  end

  test "provider_instance returns correct provider for anthropic" do
    VoiceCommand.configure do |config|
      config.provider = :anthropic
      config.anthropic_api_key = "test_key"
    end

    provider = VoiceCommand.configuration.provider_instance
    assert_instance_of VoiceCommand::Providers::AnthropicProvider, provider
  end

  test "provider_instance returns correct provider for gemini" do
    VoiceCommand.configure do |config|
      config.provider = :gemini
      config.gemini_api_key = "test_key"
    end

    provider = VoiceCommand.configuration.provider_instance
    assert_instance_of VoiceCommand::Providers::GeminiProvider, provider
  end

  test "provider_instance raises error for unknown provider" do
    VoiceCommand.configure do |config|
      config.provider = :unknown
    end

    error = assert_raises VoiceCommand::ConfigurationError do
      VoiceCommand.configuration.provider_instance
    end

    assert_match /Unknown provider: unknown/, error.message
  end

  test "effective_logger returns configured logger" do
    logger = Logger.new($stdout)

    VoiceCommand.configure do |config|
      config.logger = logger
    end

    assert_equal logger, VoiceCommand.configuration.effective_logger
  end

  test "effective_logger falls back to Rails.logger when available" do
    VoiceCommand.configure do |config|
      config.logger = nil
    end

    # Rails is available in test environment
    assert_equal Rails.logger, VoiceCommand.configuration.effective_logger
  end

  test "effective_cache returns configured cache" do
    cache = ActiveSupport::Cache::MemoryStore.new

    VoiceCommand.configure do |config|
      config.rate_limit_cache = cache
    end

    assert_equal cache, VoiceCommand.configuration.effective_cache
  end

  test "effective_cache falls back to Rails.cache when available" do
    VoiceCommand.configure do |config|
      config.rate_limit_cache = nil
    end

    # Rails is available in test environment
    assert_equal Rails.cache, VoiceCommand.configuration.effective_cache
  end
end
