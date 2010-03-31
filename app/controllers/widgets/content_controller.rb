# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Widgets::ContentController < ApplicationController
  
  def index
   
  end
  
  def show
    params[:tags].blank? ? (return return_error) : (content_tags = params[:tags])  
    params[:quantity].blank? ? quantity = 3 : quantity = params[:quantity].to_i
    params[:type].blank? ? content_type = "articles_faqs" : content_type = params[:type]
    params[:layout].blank? ? widget_layout = 'horizontal' : widget_layout = params[:layout]
    
    case content_type
    when 'faqs'
      type = 'faqs'
      contents = Faq.tagged_with_all(content_tags).main_recent_list(:limit => quantity)    
    when 'articles'
      type = 'articles'
      contents = Article.tagged_with_all(content_tags).main_recent_list(:limit => quantity)
    when 'events'
      type = 'events'
      contents = Event.tagged_with_all(content_tags).main_calendar_list({:within_days => 5, :calendar_date => Time.now.to_date, :limit => quantity})
    when 'faqs_articles'
      type = 'faqs and articles'
      faqs = Faq.tagged_with_all(content_tags).main_recent_list(:limit => quantity)
      articles = Article.tagged_with_all(content_tags).main_recent_list(:limit => quantity)
      contents = content_date_sort(articles, faqs, quantity)
    else
      return return_error
    end
    
    render :update do |page|         
      page << "document.write('#{escape_javascript(AppConfig.content_widget_styles)}');"
      page << "document.write('<div id=\"content_widget\"><h3><img src=\"/images/common/extension_icon_40x40.png\" /> eXtension #{type}: #{Tag.castlist_to_array(content_tags,false,false).join(', ')}</h3><ul>');"
      page << "document.write('<h3>There are currently no content items at this time.</h3>')" if contents.length == 0
        
      contents.each do |content| 
        case content.class.name 
        when "Faq" 
          page << "document.write('<li><a href=#{url_for :controller => '/faq', :action => :detail, :id => content.id}>');"
          page << "document.write('#{escape_javascript(content.question)}');"  
        when "Article"
          page << "document.write('<li><a href=#{url_for :controller => '/articles', :action => :page, :id => content.id}>');"
          page << "document.write('#{escape_javascript(content.title)}');"  
        when "Event"
          page << "document.write('<li><a href=#{url_for :controller => '/events', :action => :detail, :id => content.id}>');"
          page << "document.write('#{escape_javascript(content.title)}');" 
        else
          next
        end
        page << "document.write('</a></li>');"
      end
      page << "document.write('</ul>');" 
      page << "document.write('<p><a href=\"http://www.extension.org/widgets\">Create your own eXtension widget</a></p></div>');" 
    end
  end
  
  def test_widget
    render :layout => false
  end
  
  private
  
  def return_error
    render :update do |page|         
      page << "document.write('#{escape_javascript(AppConfig.content_widget_styles)}');"
      page << "document.write('<div id=\"content_widget\"><p><strong>There is a problem with the way this widget is configured.</strong> It is missing a valid content tag or content type.</p><p>Please visit the <a href=\"http://www.extension.org/widgets\">eXtension widget builder</a> and copy the code again.</p></div');"
    end
  end

end
