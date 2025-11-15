require_relative "lib/voice_command_rails/version"

Gem::Specification.new do |spec|
  spec.name        = "voice_command_rails"
  spec.version     = VoiceCommandRails::VERSION
  spec.authors     = [ "Your Name" ]
  spec.email       = [ "your.email@example.com" ]
  spec.homepage    = "https://github.com/yourusername/voice_command_rails"
  spec.summary     = "Add AI-powered voice commands to your Rails application"
  spec.description = "A Rails engine that provides voice command functionality using Gemini Flash for audio transcription and tool calling. Includes JavaScript for audio recording, Rails controllers for processing, and a simple DSL for defining voice-callable tools."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yourusername/voice_command_rails"
  spec.metadata["changelog_uri"] = "https://github.com/yourusername/voice_command_rails/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.0.0"

  # Runtime dependencies
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "ruby_llm", "~> 1.9"
  spec.add_dependency "importmap-rails", ">= 1.0"
  spec.add_dependency "stimulus-rails", ">= 1.0"
  spec.add_dependency "turbo-rails", ">= 1.0"

  # Development dependencies
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "capybara", "~> 3.0"
  spec.add_development_dependency "selenium-webdriver", "~> 4.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rails", "~> 2.0"
end
