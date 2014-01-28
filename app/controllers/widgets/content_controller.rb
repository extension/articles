# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Widgets::ContentController < ApplicationController
  # default amount of data items
  DEFAULT_LIMIT = 3
  # default width of the widget
  DEFAULT_WIDTH = 300
  
  # page with content widget builder
  def index
    @launched_tags = Tag.community_content_tags({:launchedonly => true})
    @limit = DEFAULT_LIMIT
    @width = DEFAULT_WIDTH
    @widget_code = "<script type=\"text/javascript\" src=\"#{url_for :controller => 'widgets/content', :action => :show, :escape => false, :limit => DEFAULT_LIMIT, :width => DEFAULT_WIDTH, :content_types => 'articles,news,faqs'}\"></script>"  
    render :layout => 'frontporch'
  end
  
  # generate_new_widget builds the widget from a template (rather than doing a document.write as you see in the show method). 
  # this is because we have to replace the html for the widget div instead of return js to modify it, because that js is only 
  # executing on page load. that's why we do it with show is because that's called from the js as part of the hosting page's load
  def generate_new_widget
    # handle parameters and querying data for the widget
    setup_contents
    (!@content_tags or @content_tags == 'All') ? tags_to_filter = nil : tags_to_filter = @content_tags 
    @widget_code = "<script type=\"text/javascript\" src=\"#{url_for :controller => 'widgets/content', :action => :show, :escape => false, :tags => @content_tags.join(@taglist_seperator), :quantity => @limit, :width => @width, :content_types => @content_types.join(',')}\"></script>"
    
    morelinkparams_array = []
    @filteredparams.option_values_hash.each do |keysym,value|
      key = keysym.to_s
      # ignore quantity and limit
      if(key != 'quantity' and key != 'limit')
        if(key == 'tags')
          morelinkparams_array << "#{key}=#{value.join(@taglist_seperator)}"
        elsif(value.is_a?(Array))
          morelinkparams_array << "#{key}=#{value.join(',')}"
        else
          morelinkparams_array << "#{key}=#{value}"
        end
      end
    end
    @morelinkparams = morelinkparams_array.join('&')
    
    render :layout => false
  end
  
  def show
    # handle parameters and querying data for the widget
    setup_contents
    
    morelinkparams_array = []
    @filteredparams.option_values_hash.each do |keysym,value|
      key = keysym.to_s
      # ignore quantity and limit
      if(key != 'quantity' and key != 'limit')
        if(key == 'tags')
          morelinkparams_array << "#{key}=#{value.join(@taglist_seperator)}"
        elsif(value.is_a?(Array))
          morelinkparams_array << "#{key}=#{value.join(',')}"
        else
          morelinkparams_array << "#{key}=#{value}"
        end
      end
    end
    @morelinkparams = morelinkparams_array.join('&')      
    if(!@morelinkparams.blank?)
      @morelink = "http://#{request.host_with_port}/pages/list?#{@morelinkparams}"
    else
      @morelink = "http://#{request.host_with_port}/pages/list"
    end
    
    # return js to write the widget to the page when the page hosting the widget loads
    respond_to do |format|
      format.js  
    end
  end
  
  # for testing purposes only
  def test_widget
    render :layout => false
  end
  
  private
  
  # setup from parameters, set instance variables and query db for widget data
  # some duplicated code in here, may have to revisit this
  def setup_contents
    @filteredparams = ParamsFilter.new([:apikey,:content_types,:limit,:quantity,:tags,:width],params)
    
    @width = @filteredparams.width || DEFAULT_WIDTH
    @limit = @filteredparams.limit || DEFAULT_LIMIT
    # legacy, check for quantity parameter
    if(!@filteredparams.quantity.blank?)
      @limit = @filteredparams.quantity
    end
    
    # legacy type param check
    if(!params[:type].blank?)
      case params[:type]
      when 'faqs'
        @content_types = ['faqs']
      when 'articles'
        @content_types = ['articles']
      else
        @content_types = ['articles','news','faqs']
      end
    elsif(@filteredparams.content_types)
      @content_types = @filteredparams.content_types
    else
      @content_types = ['articles','news','faqs']
    end
    
    
    # empty tags? - presume "all"
    if(@filteredparams.tags.blank? or @filteredparams.tags.include?('all'))
       alltags = true
       @content_tags = ['all']
       tag_operator = 'and'
    else
       # legacy
       if(params[:tag_operator])
         if(params[:tag_operator] == 'or')
           tag_operator = 'or'
         else
           tag_operator = 'and'
         end
       else           
         tag_operator = @filteredparams._tags.taglist_operator      
       end
       @content_tags = @filteredparams.tags
       alltags = (@content_tags.include?('all'))
    end
    
    if(tag_operator == 'or')
      @taglist_seperator = '|'
    else
      @taglist_seperator = ','
    end
      
    
    datatypes = []
    @content_types.each do |content_type|
      case content_type
      when 'faqs'
        datatypes << 'Faq'
      when 'articles'
        datatypes << 'Article'
      when 'news'
        datatypes << 'News'
      end
    end
    
    if(alltags)
       @contents = Page.recent_content(:datatypes => datatypes, :limit => @limit)
    else
       @contents = Page.recent_content(:datatypes => datatypes, :content_tags => @content_tags, :limit => @limit, :tag_operator => tag_operator)
    end
  end

end
