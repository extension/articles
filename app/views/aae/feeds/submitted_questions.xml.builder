xml.instruct!
xml.instruct! "xml-stylesheet", :href => stylesheet_path("feed")

xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do

  xml.title   "eXtension: " + ((@feed_title.nil?) ? 'FAQs' : @feed_title)
  xml.link    "rel" => "alternate", "href" => @alternate_link
  xml.link    "rel" => "self", "href" => url_for(:only_path => false)
  xml.id      url_for(:only_path => false)
  xml.updated date_format(@submitted_questions.any? ? @submitted_questions.first.created_at : Time.new)

  xml.div "class" => 'info', 'xmlns' => 'http://www.w3.org/1999/xhtml' do
    xml.text! 'This is an Atom formatted XML site feed. It is intended to be viewed in a feed reader.'
  end

  @submitted_questions.each do |question|
    xml.entry do
      xml.author  { xml.name("External User") }
      
      xml.title   "type" => "html" do
      	xml.text! question.asked_question
      end
      
      xml.link     "rel" => "alternate", "href" => url_for(:controller => 'aae/question', :action => 'index', :id => question.id, :only_path => false)
      xml.id      url_for(:controller => 'aae/question', :action => 'index', :id => question.id, :only_path => false)
      xml.updated date_format(question.updated_at)
      
      xml.content "type" => "html" do
      	xml.text! question.asked_question
      end
    end
  end

end
