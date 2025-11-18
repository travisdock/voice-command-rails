require_relative "lib/voice_command/version"

Gem::Specification.new do |spec|
  spec.name        = "voice_command"
  spec.version     = VoiceCommand::VERSION
  spec.authors     = [ "RailsConf" ]
  spec.email       = [ "maintainers@railsconf.org" ]
  spec.homepage    = "https://github.com/railsconf/voice_command"
  spec.summary     = "Drop-in voice command processing for Rails controllers."
  spec.description = "Validates uploaded audio, forwards it to RubyLLM, and returns the agent response with minimal glue required."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.1.0"
  spec.add_dependency "ruby_llm", ">= 0.1.0"
end
