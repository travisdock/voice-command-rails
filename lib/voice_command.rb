require "voice_command/version"
require "voice_command/railtie"
require "voice_command/errors"
require "voice_command/configuration"
require "voice_command/tool"
require "voice_command/result"
require "voice_command/processor"

module VoiceCommand
  class << self
    attr_writer :configuration

    # Get the current configuration
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure the gem
    # @yield [Configuration] the configuration object
    # @example
    #   VoiceCommand.configure do |config|
    #     config.provider = :openai
    #     config.openai_api_key = ENV['OPENAI_API_KEY']
    #     config.model = "gpt-4-turbo"
    #   end
    def configure
      yield(configuration)
    end

    # Reset configuration to defaults (useful for testing)
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
