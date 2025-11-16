# frozen_string_literal: true

require "rails_helper"

RSpec.describe <%= tool_class_name %>Tool do
  describe "#execute" do
    let(:tool) { described_class.new }

    # Example test - customize based on your tool's parameters
    xit "executes successfully with valid parameters" do
      result = tool.execute(
        # Add your test parameters here
        # example_param: "test value"
      )

      expect(result).to be_present
      # Add more assertions based on expected behavior
    end

    # Example test for missing required parameters
    xit "raises an error when required parameters are missing" do
      expect {
        tool.execute
      }.to raise_error(ArgumentError)
    end

    # Add more tests as needed:
    # - Test with different parameter combinations
    # - Test edge cases
    # - Test error handling
    # - Test with different user states (if applicable)
  end

  describe "tool metadata" do
    it "has a description" do
      expect(described_class.description).to be_present
    end

    it "inherits from VoiceCommandRails::Tool" do
      expect(described_class).to be < VoiceCommandRails::Tool
    end
  end
end
