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
      
      styles = '<style type="text/css" media="screen">
              <!--
              #content_widget {font-family: Helvetica, "Arial", "sans-serif";color:#222;}
              #content_widget {border:2px solid #ddd;padding:0; width:300px;}
              #content_widget h3 {color:#f47c2a; margin:0 0 10pt; padding:10px 12px 5px; border-bottom:2px solid #ddd; background:#f3f3f3}
              #content_widget ul {margin:0;padding:0; padding:0 12px 10px;}
              #content_widget li {margin:0 0 14px;padding; font-size:10.5pt;list-style:none;line-height:13pt}
              #content_widget li a {text-decoration:none;color:#333; display:block;}
              #content_widget li a:hover {text-decoration:none;color:#f47c2a;}
             	-->
              </style>'
              
      page << "document.write('#{escape_javascript(styles)}');"
      page << "document.write('<div id=\"content_widget\"><h3>eXtension #{type} for: #{Tag.castlist_to_array(content_tags,false,false).join(',')}</h3><ul>');"
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

      page << "document.write('</ul></div>');" 
    end
  end
  
  def test_widget
    # render :layout => 'pubsite'
    render :layout => false
  end
  
  private
  
  def return_error
    render :update do |page| 
      page << "document.write('<p>You must supply valid content tags and a valid content type for this widget.</p>');"
    end
  end

end
