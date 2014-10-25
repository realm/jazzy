class Jazzy::Doc < Mustache
  self.template_path = File.dirname(__FILE__) + '/..'

  def date
    DateTime.now.strftime("%Y-%m-%d")
  end

  def year
    DateTime.now.strftime("%Y")
  end

  def jazzy_version
    Jazzy::VERSION
  end
end
