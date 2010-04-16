# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Widgets::ContentController < ApplicationController
  DEFAULT_QUANTITY = 3
  
  
  def index
    @launched_categories = Category.launched_content_categories 
    @default_quantity = DEFAULT_QUANTITY
    @widget_code = "<script type=\"text/javascript\" src=\"#{url_for :controller => 'widgets/content', :action => :show, :escape => false, :quantity => @default_quantity, :type => 'articles_faqs'}\"></script>"  
    render :layout => 'widgetshome'
  end
  
  def generate_new_widget
    setup_contents
    (!@content_tags or @content_tags == 'All') ? tags_to_filter = nil : tags_to_filter = @content_tags 
    @widget_code = "<script type=\"text/javascript\" src=\"#{url_for :controller => 'widgets/content', :action => :show, :escape => false, :tags => tags_to_filter, :quantity => @quantity, :type => @content_type}\"></script>"
    render :layout => false
  end
  
  def show
    setup_contents
      
    render :update do |page|         
      page << "document.write('#{escape_javascript(AppConfig.content_widget_styles)}');"
      page << "document.write('<div id=\"content_widget\"><h3><img src=\"http://#{request.host_with_port}/images/common/extension_icon_40x40.png\" /> <span>eXtension #{@type}: #{@content_tags}</span></h3><ul>');"
      page << "document.write('<h3>There are currently no content items at this time.</h3>')" if @contents.length == 0
        
      @contents.each do |content| 
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
  
  # some duplicated code in here, may have to revisit this
  def setup_contents
    params[:tags].blank? ? (content_tags = nil) : (content_tags = params[:tags])  
    
    # if quantity is blank or zero or quantity.to_i is zero (possible non-integer), then default
    params[:quantity].blank? ? @quantity = DEFAULT_QUANTITY : @quantity = params[:quantity].to_i
    @quantity = DEFAULT_QUANTITY if @quantity == 0
    
    params[:type].blank? ? @content_type = "faqs_articles" : @content_type = params[:type]
    
    content_tags.nil? ? @content_tags = 'All' : @content_tags = Tag.castlist_to_array(content_tags,false,false).join(',')
    
    case @content_type
    when 'faqs'
      @type = 'faqs'
      if content_tags
        @contents = Faq.tagged_with_all(content_tags).main_recent_list(:limit => @quantity)
      else
        @contents = Faq.main_recent_list(:limit => @quantity)
      end
    when 'articles'
      @type = 'articles'
      if content_tags
        @contents = Article.tagged_with_all(content_tags).main_recent_list(:limit => @quantity)
      else
        @contents = Article.main_recent_list(:limit => @quantity)
      end
    when 'events'
      @type = 'events'
      if content_tags
        @contents = Event.tagged_with_all(content_tags).main_calendar_list({:within_days => 5, :calendar_date => Time.now.to_date, :limit => @quantity})
      else
        @contents = Event.main_calendar_list({:within_days => 5, :calendar_date => Time.now.to_date, :limit => @quantity})
      end
    else
      @type = 'articles and faqs'
      if content_tags
        faqs = Faq.tagged_with_all(content_tags).main_recent_list(:limit => @quantity)
        articles = Article.tagged_with_all(content_tags).main_recent_list(:limit => @quantity)
      else
        faqs = Faq.main_recent_list(:limit => @quantity)
        articles = Article.main_recent_list(:limit => @quantity)
      end
      @contents = content_date_sort(articles, faqs, @quantity)
    end
  end

end
