class Jazzy::Klass < Mustache
  self.template_path = File.dirname(__FILE__) + '/..'

  def class_name
    self[:name]
  end

  def description
    self[:overview].split("\n\n").first
  end

  def date
    DateTime.now.strftime("%Y-%m-%d")
  end

  def uri_fragment
    URI.escape(self[:name])
  end
end
