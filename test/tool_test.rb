require "test_helper"

class VoiceCommand::ToolTest < ActiveSupport::TestCase
  # Test tool for testing purposes
  class TestTool < VoiceCommand::Tool
    description "A test tool for unit testing"

    params do
      string :name, description: "User name"
      integer :age, description: "User age", minimum: 0, maximum: 150
      boolean :active, description: "Is active", default: true
      string :role, enum: [ "admin", "user", "guest" ], default: "user"
    end

    def execute(name:, age:, role: "user", active: true, context:)
      "Hello #{name}, age #{age}, role: #{role}, active: #{active}"
    end
  end

  # Minimal tool without params
  class MinimalTool < VoiceCommand::Tool
    description "A minimal tool"

    def execute(context:)
      "Executed"
    end
  end

  test "tool has description" do
    assert_equal "A test tool for unit testing", TestTool.description
  end

  test "tool name is derived from class name" do
    assert_equal "test", TestTool.tool_name
    assert_equal "minimal", MinimalTool.tool_name
  end

  test "tool generates params schema" do
    schema = TestTool.params_schema

    assert_equal "object", schema[:type]
    assert_equal 4, schema[:properties].keys.size
    assert_includes schema[:properties].keys, :name
    assert_includes schema[:properties].keys, :age
    assert_includes schema[:properties].keys, :role
    assert_includes schema[:properties].keys, :active
  end

  test "string parameter in schema" do
    schema = TestTool.params_schema
    name_param = schema[:properties][:name]

    assert_equal "string", name_param[:type]
    assert_equal "User name", name_param[:description]
  end

  test "integer parameter with constraints in schema" do
    schema = TestTool.params_schema
    age_param = schema[:properties][:age]

    assert_equal "integer", age_param[:type]
    assert_equal "User age", age_param[:description]
    assert_equal 0, age_param[:minimum]
    assert_equal 150, age_param[:maximum]
  end

  test "boolean parameter in schema" do
    schema = TestTool.params_schema
    active_param = schema[:properties][:active]

    assert_equal "boolean", active_param[:type]
    assert_equal true, active_param[:default]
  end

  test "enum parameter in schema" do
    schema = TestTool.params_schema
    role_param = schema[:properties][:role]

    assert_equal "string", role_param[:type]
    assert_equal [ "admin", "user", "guest" ], role_param[:enum]
    assert_equal "user", role_param[:default]
  end

  test "required parameters are tracked" do
    schema = TestTool.params_schema

    # name and age are required (no default)
    assert_includes schema[:required], :name
    assert_includes schema[:required], :age

    # role and active have defaults, so not required
    assert_not_includes schema[:required], :role
    assert_not_includes schema[:required], :active
  end

  test "minimal tool without params has empty schema" do
    schema = MinimalTool.params_schema

    assert_equal "object", schema[:type]
    assert_empty schema[:properties]
    assert_nil schema[:required]
  end

  test "tool can be instantiated" do
    tool = TestTool.new
    assert_instance_of TestTool, tool
  end

  test "tool can be instantiated with context" do
    tool = TestTool.new(context: { user: "Alice" })
    assert_instance_of TestTool, tool
  end

  test "execute raises NotImplementedError in base class" do
    tool = VoiceCommand::Tool.new

    error = assert_raises NotImplementedError do
      tool.execute(context: {})
    end

    assert_match /Subclasses must implement #execute/, error.message
  end

  test "tool can execute with parameters" do
    tool = TestTool.new
    result = tool.execute(name: "Alice", age: 30, context: {})

    assert_equal "Hello Alice, age 30, role: user, active: true", result
  end

  test "tool executes with all parameters" do
    tool = TestTool.new
    result = tool.execute(name: "Bob", age: 25, role: "admin", active: false, context: {})

    assert_equal "Hello Bob, age 25, role: admin, active: false", result
  end

  test "to_openai_function returns correct format" do
    tool = TestTool.new
    function = tool.to_openai_function

    assert_equal "test", function[:name]
    assert_equal "A test tool for unit testing", function[:description]
    assert_equal "object", function[:parameters][:type]
    assert_equal 4, function[:parameters][:properties].keys.size
  end

  test "to_anthropic_tool returns correct format" do
    tool = TestTool.new
    anthropic_tool = tool.to_anthropic_tool

    assert_equal "test", anthropic_tool[:name]
    assert_equal "A test tool for unit testing", anthropic_tool[:description]
    assert_equal "object", anthropic_tool[:input_schema][:type]
    assert_equal 4, anthropic_tool[:input_schema][:properties].keys.size
  end

  test "array parameter in schema" do
    class ArrayParamTool < VoiceCommand::Tool
      description "Tool with array param"

      params do
        array :tags, description: "List of tags", items: { type: "string" }
      end

      def execute(tags:, context:)
        "Tags: #{tags.join(', ')}"
      end
    end

    schema = ArrayParamTool.params_schema
    tags_param = schema[:properties][:tags]

    assert_equal "array", tags_param[:type]
    assert_equal "List of tags", tags_param[:description]
    assert_equal({ type: "string" }, tags_param[:items])
  end
end
