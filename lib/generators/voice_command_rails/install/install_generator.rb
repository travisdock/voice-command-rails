# frozen_string_literal: true

require "rails/generators"

module VoiceCommandRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install Voice Command Rails into your application"

      def create_initializer
        template "initializer.rb", "config/initializers/voice_command_rails.rb"
      end

      def add_importmap_pins
        return unless importmap_available?

        say "Adding importmap pins...", :green
        append_to_file "config/importmap.rb", importmap_pins
      end

      def mount_engine
        route 'mount VoiceCommandRails::Engine => "/voice_command_rails"'
      end

      def create_voice_tools_directory
        empty_directory "app/voice_tools"
        create_file "app/voice_tools/.keep"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end

      private

      def importmap_available?
        File.exist?("config/importmap.rb")
      end

      def importmap_pins
        <<~RUBY


          # Voice Command Rails
          pin "@hotwired/stimulus", to: "stimulus.min.js"
          pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
          pin_all_from "app/javascript/controllers", under: "controllers"
          pin "voice_command_rails", to: "voice_command_rails/index.js"
          pin "voice_command_rails/controllers/audio_recorder_controller", to: "voice_command_rails/controllers/audio_recorder_controller.js"
          pin "voice_command_rails/controllers/auto_fade_controller", to: "voice_command_rails/controllers/auto_fade_controller.js"
        RUBY
      end
    end
  end
end
