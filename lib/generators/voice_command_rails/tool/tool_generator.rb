# frozen_string_literal: true

require "rails/generators"
require "rails/generators/named_base"

module VoiceCommandRails
  module Generators
    class ToolGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Generate a new Voice Command Rails tool"

      argument :name, type: :string, required: true, banner: "ToolName"

      class_option :skip_test, type: :boolean, default: false, desc: "Skip test file generation"

      def create_tool_file
        template "tool.rb", "app/voice_tools/#{file_name}_tool.rb"
      end

      def create_test_file
        return if options[:skip_test]

        template "tool_spec.rb", "spec/voice_tools/#{file_name}_tool_spec.rb"
      end

      def show_readme
        say "\n"
        say "Tool created successfully!", :green
        say "\n"
        say "Next steps:", :yellow
        say "  1. Implement the execute method in app/voice_tools/#{file_name}_tool.rb"
        say "  2. Add any required parameters using the param helper"
        say "  3. Test your tool with: bundle exec rspec spec/voice_tools/#{file_name}_tool_spec.rb" unless options[:skip_test]
        say "  4. Try it out by recording a voice command!"
        say "\n"
      end

      private

      def tool_class_name
        name.camelize
      end

      def tool_description
        "Describe what this tool does"
      end
    end
  end
end
