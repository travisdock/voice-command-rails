module VoiceCommandRails
  class Engine < ::Rails::Engine
    isolate_namespace VoiceCommandRails

    # Register JavaScript path for importmap
    initializer "voice_command_rails.importmap", before: "importmap" do |app|
      if defined?(Importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end

    # Make assets available
    initializer "voice_command_rails.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.precompile += %w[voice_command_rails_manifest]
      end
    end

    # Set up autoload paths
    config.autoload_paths << root.join("lib")

    # Eager load configuration and tool
    config.eager_load_paths << root.join("lib/voice_command_rails")
  end
end
