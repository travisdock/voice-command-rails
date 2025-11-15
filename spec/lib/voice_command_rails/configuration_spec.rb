# frozen_string_literal: true

require "spec_helper"
require "voice_command_rails/configuration"

RSpec.describe VoiceCommandRails::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "sets default model" do
      expect(config.model).to eq("gemini-2.5-flash")
    end

    it "sets default temperature" do
      expect(config.temperature).to eq(0.3)
    end

    it "sets default max_file_size" do
      expect(config.max_file_size).to eq(5.megabytes)
    end

    it "sets default allowed_mime_types" do
      expect(config.allowed_mime_types).to include("audio/webm", "audio/mp4", "audio/mpeg")
    end

    it "sets default rate_limit_enabled" do
      expect(config.rate_limit_enabled).to be true
    end

    it "sets default rate_limit_max" do
      expect(config.rate_limit_max).to eq(5)
    end

    it "sets default rate_limit_window" do
      expect(config.rate_limit_window).to eq(1.minute)
    end

    it "sets default button_position" do
      expect(config.button_position).to eq(:bottom_right)
    end

    it "sets default enable_auto_fade" do
      expect(config.enable_auto_fade).to be true
    end

    it "sets default fade_delay" do
      expect(config.fade_delay).to eq(5.seconds)
    end

    it "sets default feature_flag_method" do
      expect(config.feature_flag_method).to eq(:voice_commands_enabled?)
    end

    it "sets default context_builder as a lambda" do
      expect(config.context_builder).to be_a(Proc)
      expect(config.context_builder.call(user: double)).to eq({})
    end

    it "sets default system_prompt" do
      expect(config.system_prompt).to be_a(String)
      expect(config.system_prompt).to include("voice assistant")
    end
  end

  describe "customization" do
    it "allows setting custom model" do
      config.model = "gemini-pro"
      expect(config.model).to eq("gemini-pro")
    end

    it "allows setting custom temperature" do
      config.temperature = 0.7
      expect(config.temperature).to eq(0.7)
    end

    it "allows setting custom context_builder" do
      custom_builder = ->(user:) { { custom: "data" } }
      config.context_builder = custom_builder
      expect(config.context_builder.call(user: double)).to eq({ custom: "data" })
    end
  end
end

RSpec.describe VoiceCommandRails do
  after do
    described_class.reset_configuration!
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(VoiceCommandRails::Configuration)
    end

    it "allows setting configuration options" do
      described_class.configure do |config|
        config.model = "custom-model"
        config.temperature = 0.8
      end

      expect(described_class.configuration.model).to eq("custom-model")
      expect(described_class.configuration.temperature).to eq(0.8)
    end
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(VoiceCommandRails::Configuration)
    end

    it "memoizes the configuration" do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".reset_configuration!" do
    it "resets the configuration to defaults" do
      described_class.configure do |config|
        config.model = "custom-model"
      end

      described_class.reset_configuration!

      expect(described_class.configuration.model).to eq("gemini-2.5-flash")
    end
  end
end
