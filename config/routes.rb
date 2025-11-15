VoiceCommandRails::Engine.routes.draw do
  # Voice command endpoint
  # POST /voice_command_rails/commands
  resources :commands, only: [:create]
end
