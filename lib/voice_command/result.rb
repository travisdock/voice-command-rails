module VoiceCommand
  # Result object for processor responses
  class Result
    attr_reader :response, :error

    def initialize(success:, response: nil, error: nil)
      @success = success
      @response = response
      @error = error
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    class << self
      def success(response:)
        new(success: true, response: response)
      end

      def failure(error:)
        new(success: false, error: error)
      end
    end
  end
end
