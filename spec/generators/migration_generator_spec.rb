# frozen_string_literal: true

require "spec_helper"
require "generator_spec"
require "generators/voice_command_rails/migration/migration_generator"

RSpec.describe VoiceCommandRails::Generators::MigrationGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  before do
    prepare_destination
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  it "creates a migration file" do
    run_generator

    migration_file = migration_file_name("db/migrate", "add_voice_commands_enabled_to_users.rb")
    expect(File.exist?(migration_file)).to be true
  end

  it "creates a migration with correct content" do
    run_generator

    migration_file = migration_file_name("db/migrate", "add_voice_commands_enabled_to_users.rb")
    migration_content = File.read(migration_file)

    expect(migration_content).to include("class AddVoiceCommandsEnabledToUsers")
    expect(migration_content).to include("add_column :users, :voice_commands_enabled, :boolean")
    expect(migration_content).to include("default: false")
    expect(migration_content).to include("null: false")
    expect(migration_content).to include("add_index :users, :voice_commands_enabled")
  end

  context "with custom table name" do
    it "creates a migration for the specified table" do
      run_generator %w[--table-name=accounts]

      migration_file = migration_file_name("db/migrate", "add_voice_commands_enabled_to_accounts.rb")
      migration_content = File.read(migration_file)

      expect(migration_content).to include("class AddVoiceCommandsEnabledToAccounts")
      expect(migration_content).to include("add_column :accounts, :voice_commands_enabled")
    end
  end

  private

  def migration_file_name(relative_destination, destination)
    absolute_destination = File.join(destination_root, relative_destination)
    return unless File.exist?(absolute_destination)

    Dir.glob("#{absolute_destination}/*").find do |file|
      File.basename(file) =~ /\d+_#{destination}$/
    end
  end
end
