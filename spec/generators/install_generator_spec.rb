# frozen_string_literal: true

require "spec_helper"
require "generator_spec"
require "generators/voice_command_rails/install/install_generator"

RSpec.describe VoiceCommandRails::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  before do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  it "creates an initializer file" do
    run_generator
    expect(destination_root).to have_structure {
      directory "config" do
        directory "initializers" do
          file "voice_command_rails.rb" do
            contains "VoiceCommandRails.configure do |config|"
            contains "config.model"
            contains "config.temperature"
            contains "config.custom_button_class"
          end
        end
      end
    }
  end

  it "creates voice_tools directory" do
    run_generator
    expect(destination_root).to have_structure {
      directory "app" do
        directory "voice_tools" do
          file ".keep"
        end
      end
    }
  end

  it "mounts the engine in routes" do
    run_generator
    routes_file = File.read(File.join(destination_root, "config/routes.rb"))
    expect(routes_file).to include('mount VoiceCommandRails::Engine => "/voice_command_rails"')
  end

  context "with importmap available" do
    before do
      File.write(File.join(destination_root, "config/importmap.rb"), "# Importmap\n")
    end

    it "adds importmap pins" do
      run_generator
      importmap_file = File.read(File.join(destination_root, "config/importmap.rb"))
      expect(importmap_file).to include("Voice Command Rails")
      expect(importmap_file).to include("@hotwired/stimulus")
      expect(importmap_file).to include("voice_command_rails")
    end
  end

  context "without importmap" do
    it "skips importmap pins" do
      run_generator
      expect(File.exist?(File.join(destination_root, "config/importmap.rb"))).to be false
    end
  end
end
