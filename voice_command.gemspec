require_relative "lib/voice_command/version"

Gem::Specification.new do |spec|
  spec.name        = "voice_command"
  spec.version     = VoiceCommand::VERSION
  spec.authors     = [ "Your Name" ]
  spec.email       = [ "your.email@example.com" ]
  spec.homepage    = "https://github.com/yourusername/voice_command"
  spec.summary     = "Add voice command capabilities to Rails applications with LLM integration"
  spec.description = "A simple Rails gem that provides audio processing, LLM integration, and tool calling for voice-enabled applications. Supports OpenAI, Anthropic, and Gemini providers."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"

  # Core dependencies
  spec.add_dependency "marcel", "~> 1.0" # MIME type detection

  # Optional provider dependencies (at least one required)
  # Users should add the provider gem they want to use to their Gemfile
end
