xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.id(@id)
  xml.title(@title)
  xml.link("rel" => "alternate", "href" => root_url)
  xml.link("rel" => "self", "href" => request.url)
  xml.updated(@updated_at.xmlschema)
  xml.author do
    xml.name("Contributors")
  end
  @pages.each do |page|
    xml << render(:partial => 'page', :locals => {:page => page})
  end
end
