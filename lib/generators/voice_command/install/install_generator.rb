require "rails/generators"

module VoiceCommand
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates VoiceCommand initializer and JavaScript controller"

      def copy_initializer
        template "initializer.rb", "config/initializers/voice_command.rb"
      end

      def copy_stimulus_controller
        copy_file "audio_recorder_controller.js",
                  "app/javascript/controllers/voice_command_audio_recorder_controller.js"
      end

      def show_next_steps
        say "\n" + "=" * 70
        say "VoiceCommand installed successfully!", :green
        say "=" * 70

        say "\nNext steps:", :yellow
        say "  1. Configure your LLM provider in config/initializers/voice_command.rb"
        say "  2. Add your API key to Rails credentials:"
        say "     rails credentials:edit"
        say "     # Add: openai_api_key: your_key_here"
        say "  3. Define your tools (see examples in initializer)"
        say "  4. Create a controller action to handle audio uploads:"
        say "     rails generate controller VoiceCommands create"
        say "  5. Add a route for the controller:"
        say "     post '/voice_commands', to: 'voice_commands#create'"
        say "  6. Add the voice recorder form to your view (see initializer for example)"

        say "\nDocumentation:", :yellow
        say "  https://github.com/yourusername/voice_command"

        say "\n" + "=" * 70 + "\n"
      end
    end
  end
end
