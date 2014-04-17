xml.entry do
  xml.id(page.id_and_link)
  xml.title("type" => "html") do
    xml.text!(page.title)
  end
  xml.link("rel" => "alternate", "href" => page.id_and_link)
  xml.updated(page.source_updated_at.xmlschema)
  page.tag_names.each do |name|
    xml.category("scheme" => root_url, "term" => name)
  end
  xml.content("type" => "html") do
    xml.text!(page.content)
  end
  xml.author do
    xml.name("Contributors")
  end
end
