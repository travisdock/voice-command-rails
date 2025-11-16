# frozen_string_literal: true

require "spec_helper"
require "generator_spec"
require "generators/voice_command_rails/tool/tool_generator"

RSpec.describe VoiceCommandRails::Generators::ToolGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  before do
    prepare_destination
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  it "creates a tool file with the correct name" do
    run_generator %w[CreateTask]

    expect(destination_root).to have_structure {
      directory "app" do
        directory "voice_tools" do
          file "create_task_tool.rb" do
            contains "class CreateTaskTool < VoiceCommandRails::Tool"
            contains "def execute(**args)"
            contains "description"
          end
        end
      end
    }
  end

  it "creates a test file" do
    run_generator %w[CreateTask]

    expect(destination_root).to have_structure {
      directory "spec" do
        directory "voice_tools" do
          file "create_task_tool_spec.rb" do
            contains "RSpec.describe CreateTaskTool do"
            contains 'describe "#execute"'
            contains "describe \"tool metadata\""
          end
        end
      end
    }
  end

  it "skips test file when --skip-test is passed" do
    run_generator %w[CreateTask --skip-test]

    expect(File.exist?(File.join(destination_root, "spec/voice_tools/create_task_tool_spec.rb"))).to be false
  end

  it "handles multi-word tool names correctly" do
    run_generator %w[SendEmail]

    expect(destination_root).to have_structure {
      directory "app" do
        directory "voice_tools" do
          file "send_email_tool.rb" do
            contains "class SendEmailTool < VoiceCommandRails::Tool"
          end
        end
      end
    }
  end
end
