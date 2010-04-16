# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Widgets::ContentController < ApplicationController
  
  def index
    @launched_categories = Category.launched_content_categories  
    render :layout => 'widgetshome'
  end
  
  def generate_new_widget
    params[:tags].blank? ? (@error = true) : (content_tags = params[:tags])  
    params[:quantity].blank? ? quantity = 3 : quantity = params[:quantity].to_i
    params[:type].blank? ? content_type = "faqs_articles" : content_type = params[:type]
    
    if !@error
      @error = true if !@content_type_hash = get_contents(content_type, content_tags, quantity)
      @content_tags = Tag.castlist_to_array(params[:tags],false,false).join(',')
    end
    
    @widget_code = "<script type=\"text/javascript\" src=\"#{url_for :controller => 'widgets/content', :action => :show, :escape => false, :tags => @content_tags, :quantity => quantity, :type => content_type}\"></script>"
    
    render :layout => false
  end
  
  def show
    params[:tags].blank? ? (return return_error) : (content_tags = params[:tags])  
    params[:quantity].blank? ? quantity = 3 : quantity = params[:quantity].to_i
    params[:type].blank? ? content_type = "articles_faqs" : content_type = params[:type]
    
    return return_error if !content_type_hash = get_contents(content_type, content_tags, quantity)
      
    render :update do |page|         
      page << "document.write('#{escape_javascript(AppConfig.content_widget_styles)}');"
      page << "document.write('<div id=\"content_widget\"><h3><img src=\"http://#{request.host_with_port}/images/common/extension_icon_40x40.png\" /> <span>eXtension #{content_type_hash[:type]}: #{Tag.castlist_to_array(content_tags,false,false).join(', ')}</span></h3><ul>');"
      page << "document.write('<li>There are currently no content items at this time.</li>')" if content_type_hash[:contents].length == 0
        
      content_type_hash[:contents].each do |content| 
        case content.class.name 
        when "Faq" 
          page << "document.write('<li><a href=#{url_for :controller => '/faq', :action => :detail, :id => content.id, :only_path => false}>');"
          page << "document.write('#{escape_javascript(content.question)}');"  
        when "Article"
          page << "document.write('<li><a href=#{url_for :controller => '/articles', :action => :page, :id => content.id, :only_path => false}>');"
          page << "document.write('#{escape_javascript(content.title)}');"  
        when "Event"
          page << "document.write('<li><a href=#{url_for :controller => '/events', :action => :detail, :id => content.id, :only_path => false}>');"

          page << "document.write('#{escape_javascript(content.title)}');" 
        else
          next
        end
        page << "document.write('</a></li>');"
      end
      page << "document.write('</ul>');" 
      page << "document.write('<p><a href=\"http://#{request.host}/widgets\">Create your own eXtension widget</a></p></div>');" 
    end
  end
  
  def test_widget
    render :layout => false
  end
  
  private
  
  def return_error
    render :update do |page|         
      page << "document.write('#{escape_javascript(AppConfig.content_widget_styles)}');"
      page << "document.write('<div id=\"content_widget\" class=\"error\"><p><strong>There is a problem with the way this widget is configured.</strong> It is missing a valid content tag or content type.</p><p>Please visit the <a href=\"http://#{request.host}/widgets\">eXtension widget builder</a> and copy the code again.</p></div');"
    end
  end
  
  def get_contents(content_type, content_tags, quantity)
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
      return nil
    end
    
    return {:contents => contents, :type => type}
    
  end

end
