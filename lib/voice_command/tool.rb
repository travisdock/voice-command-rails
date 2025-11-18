module VoiceCommand
  # Base class for all voice command tools
  # Tools define functions that the LLM can call to perform actions
  #
  # @example
  #   class CreateTodoTool < VoiceCommand::Tool
  #     description "Create a new todo item"
  #
  #     params do
  #       string :title, description: "The todo title"
  #       string :priority, enum: ["low", "medium", "high"], default: "medium"
  #     end
  #
  #     def execute(title:, priority: "medium", context:)
  #       user = context[:user]
  #       todo = user.todos.create!(title: title, priority: priority)
  #       "Created: #{todo.title}"
  #     end
  #   end
  class Tool
    class << self
      # Set or get the tool description
      def description(text = nil)
        if text
          @description = text
        else
          @description
        end
      end

      # Get the tool name (derived from class name)
      def tool_name
        @tool_name ||= name.split("::").last.underscore.gsub("_tool", "")
      end

      # Define parameters for the tool
      def params(&block)
        @params_builder = block
      end

      # Get the parameters schema
      def params_schema
        return @params_schema if @params_schema

        builder = ParamsBuilder.new
        builder.instance_eval(&@params_builder) if @params_builder
        @params_schema = builder.to_schema
      end
    end

    def initialize(context: {})
      @context = context
    end

    # Execute the tool with given parameters
    # Subclasses must implement this method
    # @param context [Hash] Request context (user, etc.)
    # @return [String] Natural language response
    def execute(**args)
      raise NotImplementedError, "Subclasses must implement #execute"
    end

    # Convert tool to OpenAI function format
    def to_openai_function
      {
        name: self.class.tool_name,
        description: self.class.description,
        parameters: self.class.params_schema
      }
    end

    # Convert tool to Anthropic tool format
    def to_anthropic_tool
      {
        name: self.class.tool_name,
        description: self.class.description,
        input_schema: self.class.params_schema
      }
    end

    # For RubyLLM/Gemini compatibility
    # RubyLLM tools need to inherit from RubyLLM::Tool
    # So we provide the same interface but don't require the inheritance
    def self.inherited(subclass)
      super
      # If RubyLLM is available, make the tool compatible
      if defined?(RubyLLM::Tool)
        # We'll handle this by making tools work with both systems
      end
    end

    # Params builder for DSL
    class ParamsBuilder
      def initialize
        @properties = {}
        @required = []
      end

      def string(name, description: nil, enum: nil, default: nil)
        prop = { type: "string" }
        prop[:description] = description if description
        prop[:enum] = enum if enum
        prop[:default] = default if default

        @properties[name] = prop
        @required << name unless default
      end

      def integer(name, description: nil, minimum: nil, maximum: nil, default: nil)
        prop = { type: "integer" }
        prop[:description] = description if description
        prop[:minimum] = minimum if minimum
        prop[:maximum] = maximum if maximum
        prop[:default] = default if default

        @properties[name] = prop
        @required << name unless default
      end

      def boolean(name, description: nil, default: nil)
        prop = { type: "boolean" }
        prop[:description] = description if description
        prop[:default] = default if default

        @properties[name] = prop
        @required << name if default.nil?
      end

      def array(name, description: nil, items: nil, default: nil)
        prop = { type: "array" }
        prop[:description] = description if description
        prop[:items] = items if items
        prop[:default] = default if default

        @properties[name] = prop
        @required << name unless default
      end

      def to_schema
        schema = {
          type: "object",
          properties: @properties
        }
        schema[:required] = @required if @required.any?
        schema
      end
    end
  end
end
