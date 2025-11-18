require "test_helper"
require "voice_command/validators/rate_limiter"

class VoiceCommand::Validators::RateLimiterTest < ActiveSupport::TestCase
  class MockUser
    attr_reader :id

    def initialize(id)
      @id = id
    end
  end

  setup do
    VoiceCommand.reset_configuration!
    @user = MockUser.new(123)
  end

  teardown do
    VoiceCommand::Validators::RateLimiter.reset!(@user)
  end

  test "allows requests within rate limit" do
    VoiceCommand.configure do |config|
      config.rate_limit_max_requests = 5
      config.rate_limit_window = 60
    end

    # Should allow 5 requests
    5.times do
      assert VoiceCommand::Validators::RateLimiter.check!(@user)
    end
  end

  test "raises error when rate limit exceeded" do
    VoiceCommand.configure do |config|
      config.rate_limit_max_requests = 3
      config.rate_limit_window = 60
    end

    # Use up the limit
    3.times do
      VoiceCommand::Validators::RateLimiter.check!(@user)
    end

    # Next request should fail
    error = assert_raises VoiceCommand::RateLimitExceeded do
      VoiceCommand::Validators::RateLimiter.check!(@user)
    end

    assert_match /Rate limit exceeded/, error.message
    assert_match /3 requests per 60 seconds/, error.message
  end

  test "returns current count" do
    VoiceCommand.configure do |config|
      config.rate_limit_max_requests = 10
    end

    assert_equal 0, VoiceCommand::Validators::RateLimiter.current_count(@user)

    VoiceCommand::Validators::RateLimiter.check!(@user)
    assert_equal 1, VoiceCommand::Validators::RateLimiter.current_count(@user)

    VoiceCommand::Validators::RateLimiter.check!(@user)
    assert_equal 2, VoiceCommand::Validators::RateLimiter.current_count(@user)
  end

  test "reset! clears the counter" do
    VoiceCommand.configure do |config|
      config.rate_limit_max_requests = 10
    end

    3.times { VoiceCommand::Validators::RateLimiter.check!(@user) }
    assert_equal 3, VoiceCommand::Validators::RateLimiter.current_count(@user)

    VoiceCommand::Validators::RateLimiter.reset!(@user)
    assert_equal 0, VoiceCommand::Validators::RateLimiter.current_count(@user)
  end

  test "skips rate limiting when no user provided" do
    VoiceCommand.configure do |config|
      config.rate_limit_max_requests = 1
    end

    # Should not raise even with very low limit
    10.times do
      assert VoiceCommand::Validators::RateLimiter.check!(nil)
    end
  end

  test "different users have separate rate limits" do
    user1 = MockUser.new(1)
    user2 = MockUser.new(2)

    VoiceCommand.configure do |config|
      config.rate_limit_max_requests = 2
    end

    # Use up user1's limit
    2.times { VoiceCommand::Validators::RateLimiter.check!(user1) }

    # user1 should be rate limited
    assert_raises VoiceCommand::RateLimitExceeded do
      VoiceCommand::Validators::RateLimiter.check!(user1)
    end

    # But user2 should still work
    assert VoiceCommand::Validators::RateLimiter.check!(user2)
  ensure
    VoiceCommand::Validators::RateLimiter.reset!(user1)
    VoiceCommand::Validators::RateLimiter.reset!(user2)
  end
end
