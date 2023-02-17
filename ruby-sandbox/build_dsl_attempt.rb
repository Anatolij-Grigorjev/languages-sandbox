module DocumentDsl
  def document(attrs)
    {
      name: "document",
      attributes: { family: "flow" }.merge(attrs),
      children: yield([]),
    }
  end

  def application(attrs)
    {
      name: "application",
      attributes: attrs,
      children: yield([]),
    }
  end

  def service(attrs)
    {
      name: "service",
      attributes: attrs,
      children: yield([]),
    }
  end

  def structure(attrs)
    {
      name: "structure",
      attributes: attrs,
      children: [],
    }
  end
end
