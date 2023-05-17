class TypedValue
  TYPES = %i(numeric text expression)

  TYPES.each do |type_symbol|
    define_method("#{type_symbol}?".to_sym) do
      @type == type_symbol
    end
  end

  class << self
    TYPES.each do |type_symbol|
      define_method("new_#{type_symbol}".to_sym) do |value|
        TypedValue.new(type_symbol, value)
      end
    end
  end

  def initialize(type, value)
    validate_type!(type)

    @type = type
    @value = value
  end

  private

  def validate_type!(type)
    return if TYPES.include?(type)

    raise StandardError.new("Unsupported type: #{type}")
  end
end
