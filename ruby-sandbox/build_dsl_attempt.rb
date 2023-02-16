module DocumentDsl
  def document(attrs)
    { family: "flow" }
      .merge(attrs)
      .merge({ applications: yield([]) })
  end

  def application(attrs)
    attrs.merge({ services: yield([]) })
  end

  def service(attrs)
    attrs.merge({ structures: yield([]) })
  end

  def structure(attrs)
    attrs
  end
end
