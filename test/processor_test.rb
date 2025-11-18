require "test_helper"
require "rack/test"
require "ostruct"

class ProcessorTest < ActiveSupport::TestCase
  setup do
    @audio_file = Rack::Test::UploadedFile.new(file_fixture("sample.ogg"), "audio/ogg")
    @chat = FakeChat.new(OpenStruct.new(content: "completed"))

    VoiceCommand.reset_configuration!
    VoiceCommand.configure do |config|
      config.chat_factory = ->(**) { @chat }
      config.tool_provider = ->(context) { [context[:tool]].compact }
      config.allowed_content_types = ["audio/"]
      config.audio_max_bytes = 1.megabyte
    end
  end

  test "process returns success with parsed text" do
    tool = Object.new
    result = VoiceCommand.process(
      audio: @audio_file,
      prompt: "Handle the audio",
      context: { tool: tool }
    )

    assert result[:success]
    assert_equal "completed", result[:message]
    assert_equal tool, @chat.tools.first
    assert_equal "Handle the audio", @chat.asked[:prompt]
    assert_equal @audio_file.tempfile.path, @chat.asked[:with]
  end

  test "process returns failure on invalid audio" do
    VoiceCommand.configure do |config|
      config.allowed_content_types = ["audio/wav"]
    end

    result = VoiceCommand.process(
      audio: @audio_file,
      prompt: "Do it",
      context: {}
    )

    refute result[:success]
    assert_match(/Unsupported audio file/, result[:message])
  end

  private

  class FakeChat
    attr_reader :tools, :asked

    def initialize(response)
      @response = response
      @tools = []
    end

    def with_tool(tool)
      @tools << tool
      self
    end

    def ask(prompt, with:)
      @asked = { prompt: prompt, with: with }
      @response
    end
  end
end
