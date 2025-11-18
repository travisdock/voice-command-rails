# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-18

### Added
- Initial release of VoiceCommand gem
- Multi-provider LLM support (OpenAI, Anthropic, Gemini)
- Configuration DSL for easy setup
- Tool base class with parameter DSL
- Tool registration system
- Core processor for audio processing
- Audio file validation
- Rate limiting per user
- Structured JSON logging
- Result object for success/failure responses
- Stimulus audio recorder controller
- Install generator with templates
- Comprehensive README with examples
- Full test coverage (47+ tests, 95+ assertions)

### Features
- OpenAI provider with Whisper transcription and function calling
- Anthropic (Claude) provider with tool use
- Google Gemini provider via ruby_llm
- Configurable audio validation (file size, content types)
- Configurable rate limiting (max requests, time window)
- Tool parameter types: string, integer, boolean, array
- Parameter constraints: enum, minimum, maximum, default values
- Context injection for tool execution
- Turbo Native support for iOS and Android
- Web Audio API fallback for browsers

### Documentation
- Quick start guide (5 minutes to first voice command)
- Configuration examples for all providers
- Tool definition guide
- Controller integration examples
- View integration examples
- Turbo Native integration guide

### Dependencies
- Rails >= 7.0
- Marcel ~> 1.0 (MIME type detection)
- Optional: ruby-openai (for OpenAI)
- Optional: anthropic-sdk-ruby (for Anthropic)
- Optional: ruby_llm (for Gemini)

[0.1.0]: https://github.com/yourusername/voice_command/releases/tag/v0.1.0
