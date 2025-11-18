require "rails/generators"

module VoiceCommand
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :skip_stimulus, type: :boolean, default: false, desc: "Skip copying the audio recorder Stimulus controller."

      def copy_stimulus_controller
        return if options[:skip_stimulus]

        template "audio_recorder_controller.js", "app/javascript/controllers/audio_recorder_controller.js"
      end
    end
  end
end
