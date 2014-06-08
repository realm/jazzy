class Jazzy::Klass < Mustache
  self.template_path = File.dirname(__FILE__) + '/..'

  # def name
  #   self[:root]["Other"][0]["Name"]
  # end

  def rendered_abstract
    $markdown.render self[:abstract]
  end

  def rendered_discussion
    $markdown.render self[:discussion]
  end

  def rendered_abstract_for_overview
    self[:abstract].chop! + ' <a class="overview-bulk-toggle">More...</a>'
  end

  def date
    DateTime.now.strftime("%Y-%m-%d")
  end

  def uri_fragment
    URI.escape(self[:name])
  end
end
