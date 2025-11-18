module VoiceCommand
  module Validators
    # Rate limiting for voice command requests
    class RateLimiter
      class << self
        # Check if user has exceeded rate limit
        # @param user [Object] The user to check (must respond to :id)
        # @raise [RateLimitExceeded] If rate limit exceeded
        # @return [true] If within rate limit
        def check!(user)
          config = VoiceCommand.configuration

          # Skip rate limiting if no user or no cache configured
          return true unless user
          return true unless config.effective_cache

          key = rate_limit_key(user)
          cache = config.effective_cache

          # Increment counter
          current = cache.increment(key, 1, expires_in: config.rate_limit_window)

          # If increment failed (key didn't exist), initialize it
          unless current
            cache.write(key, 1, expires_in: config.rate_limit_window)
            current = 1
          end

          # Check if limit exceeded
          if current > config.rate_limit_max_requests
            raise RateLimitExceeded,
                  "Rate limit exceeded: #{config.rate_limit_max_requests} requests per #{config.rate_limit_window} seconds"
          end

          true
        end

        # Get current request count for user
        # @param user [Object] The user to check
        # @return [Integer] Current request count
        def current_count(user)
          return 0 unless user

          config = VoiceCommand.configuration
          return 0 unless config.effective_cache

          key = rate_limit_key(user)
          config.effective_cache.read(key) || 0
        end

        # Reset rate limit for user (useful for testing)
        # @param user [Object] The user to reset
        def reset!(user)
          return unless user

          config = VoiceCommand.configuration
          return unless config.effective_cache

          key = rate_limit_key(user)
          config.effective_cache.delete(key)
        end

        private

        def rate_limit_key(user)
          "voice_command:rate:#{user.id}"
        end
      end
    end
  end
end
