class JazzyHTML < Redcarpet::Render::HTML
  def paragraph(text)
    "<p class=\"para\">#{text}</p>"
  end
end

$markdown = Redcarpet::Markdown.new(JazzyHTML)
