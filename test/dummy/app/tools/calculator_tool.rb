class CalculatorTool < VoiceCommand::Tool
  description "Perform basic arithmetic operations"

  params do
    integer :a, description: "First number"
    integer :b, description: "Second number"
    string :operation, description: "Operation to perform", enum: [ "add", "subtract", "multiply", "divide" ]
  end

  def execute(a:, b:, operation:, context:)
    result = case operation
             when "add"
               a + b
             when "subtract"
               a - b
             when "multiply"
               a * b
             when "divide"
               return "Cannot divide by zero" if b.zero?
               a / b
             else
               return "Unknown operation: #{operation}"
             end

    "#{a} #{operation} #{b} = #{result}"
  end
end
