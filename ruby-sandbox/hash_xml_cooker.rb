class Hash
  def to_xml
    <<-XML
        <#{self[:name]} #{self[:attributes].map { |attr_name, attr_value| "#{attr_name}=\"#{attr_value}\"" }.join(" ")}>
            #{self[:children].map(&:to_xml).join("\n")}
        </#{self[:name]}>
XML
  end
end
