# frozen_string_literal: true

require "spec_helper"
require "voice_command_rails/tool"

RSpec.describe VoiceCommandRails::Tool do
  # Create a test tool class
  let(:test_tool_class) do
    Class.new(described_class) do
      description "Test tool for specs"

      params do
        string :name, description: "Name parameter"
      end

      def execute(name:)
        "Hello, #{name}!"
      end
    end
  end

  let(:test_tool) { test_tool_class.new }

  describe "inheritance" do
    it "inherits from RubyLLM::Tool" do
      expect(described_class).to be < RubyLLM::Tool
    end
  end

  describe ".param helper" do
    let(:simple_tool_class) do
      Class.new(described_class) do
        description "Simple tool with param helper"

        param :title, desc: "Title parameter"
        param :status, desc: "Status parameter", required: false
        param :count, type: :integer, desc: "Count parameter"

        def execute(title:, status: "active", count:)
          { title: title, status: status, count: count }
        end
      end
    end

    it "defines parameters using the param helper" do
      tool = simple_tool_class.new
      expect(tool).to respond_to(:execute)
    end
  end

  describe "#execute" do
    it "must be implemented by subclasses" do
      bare_tool = Class.new(described_class).new
      expect { bare_tool.execute }.to raise_error(NotImplementedError)
    end

    it "can be called with parameters" do
      result = test_tool.execute(name: "World")
      expect(result).to eq("Hello, World!")
    end
  end

  describe "helper methods" do
    let(:tool_with_helpers) do
      Class.new(described_class) do
        description "Tool that uses helpers"

        params do
          string :message
        end

        def execute(message:)
          if user_signed_in?
            "User: #{current_user.name}, Message: #{message}"
          else
            "No user, Message: #{message}"
          end
        end
      end.new
    end

    describe "#current_user" do
      it "returns nil when Current is not defined" do
        tool = test_tool
        expect(tool.send(:current_user)).to be_nil
      end

      context "when Current is defined" do
        before do
          stub_const("Current", Class.new do
            class << self
              attr_accessor :user
            end
          end)
        end

        it "returns Current.user" do
          user = double("User", name: "Test User")
          Current.user = user

          expect(tool_with_helpers.send(:current_user)).to eq(user)
        end
      end
    end

    describe "#user_signed_in?" do
      it "returns false when no user" do
        expect(test_tool.send(:user_signed_in?)).to be false
      end

      context "when Current.user is present" do
        before do
          stub_const("Current", Class.new do
            class << self
              attr_accessor :user
            end
          end)
        end

        it "returns true when user is present" do
          Current.user = double("User")
          expect(tool_with_helpers.send(:user_signed_in?)).to be true
        end

        it "returns false when user is nil" do
          Current.user = nil
          expect(tool_with_helpers.send(:user_signed_in?)).to be false
        end
      end
    end
  end
end
