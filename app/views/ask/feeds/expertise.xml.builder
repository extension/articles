xml.instruct!
xml.instruct! "xml-stylesheet", :href => stylesheet_path("feed")

xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do

  xml.title   "eXtension: Users signed up for the #{@category.name} area of expertise"
  xml.subtitle "Users signed up for expertise in the faq application"
  xml.link    "rel" => "alternate", "href" => @alternate_link
  xml.link    "rel" => "self", "href" => url_for(:only_path => false)
  xml.id      url_for(:only_path => false)
  xml.updated date_format(@updated_time)

  xml.div "class" => 'info', 'xmlns' => 'http://www.w3.org/1999/xhtml' do
    xml.text! 'This is an Atom formatted XML site feed. It is intended to be viewed in a feed reader.'
  end

  @users.each do |user|
    xml.entry do
      xml.author  { xml.name(user.get_first_last_name) }
      xml.title   "type" => "html" do
      	xml.text! "#{user.get_first_last_name} added #{@category.name} to expertise."
      end
      
      xml.link    "rel" => "alternate", "href" => url_for(:only_path => false, :controller => 'account', :action => 'aaeprofile', :id => user.login)
      xml.id     url_for(:only_path => false, :controller => 'account', :action => 'aaeprofile', :id => user.login) 
      xml.updated date_format(user.added_at.to_time)
      
      xml.content "type" => "html" do
      	xml.text! "#{user.get_first_last_name} added #{@category.name} to expertise."
      end
    end
  end

end
