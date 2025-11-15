# frozen_string_literal: true

# Pin all JavaScript controllers from the gem
pin_all_from File.expand_path("../app/javascript/voice_command_rails", __dir__),
             under: "voice_command_rails",
             to: "voice_command_rails"
