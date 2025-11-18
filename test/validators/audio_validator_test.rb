require "test_helper"
require "tempfile"
require "voice_command/validators/audio_validator"

class VoiceCommand::Validators::AudioValidatorTest < ActiveSupport::TestCase
  setup do
    VoiceCommand.reset_configuration!
  end

  test "validates valid audio file" do
    file = create_temp_audio_file("test.mp3", "audio/mpeg", 1024)

    assert VoiceCommand::Validators::AudioValidator.validate!(file)
  ensure
    file&.close
    file&.unlink
  end

  test "raises error when no file provided" do
    error = assert_raises VoiceCommand::InvalidAudioFile do
      VoiceCommand::Validators::AudioValidator.validate!(nil)
    end

    assert_match /No audio file provided/, error.message
  end

  test "raises error when file object is invalid" do
    invalid_file = "not a file object"

    error = assert_raises VoiceCommand::InvalidAudioFile do
      VoiceCommand::Validators::AudioValidator.validate!(invalid_file)
    end

    assert_match /Invalid file object/, error.message
  end

  test "raises error when file size exceeds limit" do
    VoiceCommand.configure do |config|
      config.max_file_size = 1024 # 1 KB
    end

    file = create_temp_audio_file("large.mp3", "audio/mpeg", 2048) # 2 KB

    error = assert_raises VoiceCommand::FileTooLarge do
      VoiceCommand::Validators::AudioValidator.validate!(file)
    end

    assert_match /File size/, error.message
    assert_match /exceeds maximum/, error.message
  ensure
    file&.close
    file&.unlink
  end

  test "raises error for invalid content type" do
    VoiceCommand.configure do |config|
      config.allowed_content_types = [ "audio/mpeg" ]
    end

    file = create_temp_audio_file("test.txt", "text/plain", 1024)

    error = assert_raises VoiceCommand::InvalidAudioFile do
      VoiceCommand::Validators::AudioValidator.validate!(file)
    end

    assert_match /Invalid audio format/, error.message
  ensure
    file&.close
    file&.unlink
  end

  test "accepts various audio formats" do
    formats = [
      [ "test.webm", "audio/webm" ],
      [ "test.mp3", "audio/mpeg" ],
      [ "test.mp4", "audio/mp4" ],
      [ "test.m4a", "audio/mp4" ],
      [ "test.ogg", "audio/ogg" ]
    ]

    formats.each do |filename, content_type|
      file = create_temp_audio_file(filename, content_type, 1024)

      assert VoiceCommand::Validators::AudioValidator.validate!(file),
             "Should accept #{content_type}"
    ensure
      file&.close
      file&.unlink
    end
  end

  private

  def create_temp_audio_file(name, content_type, size)
    # Create file with proper extension so Marcel can detect it
    file = Tempfile.new([ File.basename(name, ".*"), File.extname(name) ])
    file.write("a" * size)
    file.rewind

    # Stub Marcel to return the expected content type
    Marcel::MimeType.stubs(:for).with(file).returns(content_type)

    file
  end
end
