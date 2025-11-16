# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module VoiceCommandRails
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Generate a migration to add voice_commands_enabled to users table"

      class_option :table_name, type: :string, default: "users", desc: "The table name to add the column to"

      def create_migration_file
        migration_template "migration.rb", "db/migrate/add_voice_commands_enabled_to_#{table_name}.rb"
      end

      def show_readme
        say "\n"
        say "Migration created successfully!", :green
        say "\n"
        say "Next steps:", :yellow
        say "  1. Run the migration: rails db:migrate"
        say "  2. Enable voice commands for specific users:"
        say "     user.update(voice_commands_enabled: true)"
        say "\n"
        say "The voice command button will only appear for users where:", :yellow
        say "  current_user.voice_commands_enabled? returns true"
        say "\n"
      end

      private

      def table_name
        options[:table_name]
      end

      def migration_class_name
        "AddVoiceCommandsEnabledTo#{table_name.camelize}"
      end
    end
  end
end
