require "voice_command/view_helpers"

module VoiceCommand
  class Railtie < ::Rails::Railtie
    initializer "voice_command.view_helpers" do
      ActiveSupport.on_load :action_view do
        include VoiceCommand::ViewHelpers
      end
    end
  end
end
