xml.instruct!

xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do

  xml.title   "Invalid Feed Request"
  xml.link    "href" => url_for(:only_path => false)
  xml.id      url_for(:only_path => false)
  xml.updated date_format(Time.now.utc)

  xml.entry "xmlns" => "http://www.w3.org/2005/Atom" do
    xml.title "type" => "html" do
    	xml.text! "Invalid request"
    end
    
    xml.link    "href" => url_for(:only_path => false)
    xml.id      url_for(:only_path => false)
    xml.updated date_format(Time.now.utc)
    xml.author  { xml.name "FAQ Administrator" }
    xml.content "type" => "html" do
      xml.text! @error_message
    end
  end

end
