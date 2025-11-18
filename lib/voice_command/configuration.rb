module VoiceCommand
  class Configuration
    # LLM Provider settings
    attr_accessor :provider, :model
    attr_accessor :openai_api_key, :anthropic_api_key, :gemini_api_key

    # Audio validation settings
    attr_accessor :max_file_size, :allowed_content_types

    # Rate limiting settings
    attr_accessor :rate_limit_max_requests, :rate_limit_window, :rate_limit_cache

    # Logging
    attr_accessor :logger

    # Registered tools
    attr_reader :tools

    def initialize
      # Default LLM settings
      @provider = :openai
      @model = "gpt-4-turbo"

      # Default audio validation settings
      @max_file_size = 5 * 1024 * 1024 # 5 MB
      @allowed_content_types = [ "audio/webm", "audio/mp4", "audio/mpeg", "audio/m4a", "audio/ogg" ]

      # Default rate limiting settings
      @rate_limit_max_requests = 5
      @rate_limit_window = 60 # seconds
      @rate_limit_cache = nil # Will default to Rails.cache if available

      # Default logger
      @logger = nil # Will default to Rails.logger if available

      # Initialize empty tools array
      @tools = []
    end

    # Register a tool class
    def register_tool(tool_class)
      @tools << tool_class unless @tools.include?(tool_class)
    end

    # Get the provider instance based on current configuration
    def provider_instance
      case @provider
      when :openai
        require "voice_command/providers/openai_provider"
        Providers::OpenAIProvider.new(self)
      when :anthropic
        require "voice_command/providers/anthropic_provider"
        Providers::AnthropicProvider.new(self)
      when :gemini
        require "voice_command/providers/gemini_provider"
        Providers::GeminiProvider.new(self)
      else
        raise ConfigurationError, "Unknown provider: #{@provider}. Supported providers: :openai, :anthropic, :gemini"
      end
    end

    # Get the effective logger (fallback to Rails.logger if available)
    def effective_logger
      @logger || (defined?(Rails) ? Rails.logger : Logger.new($stdout))
    end

    # Get the effective cache (fallback to Rails.cache if available)
    def effective_cache
      @rate_limit_cache || (defined?(Rails) ? Rails.cache : nil)
    end
  end
end
