# frozen_string_literal: true

class <%= migration_class_name %> < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    add_column :<%= table_name %>, :voice_commands_enabled, :boolean, default: false, null: false
    add_index :<%= table_name %>, :voice_commands_enabled
  end
end
