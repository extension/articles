# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class FeedsController < ApplicationController
  skip_before_filter :personalize, :except => :index
    
  def index
    set_title('Feeds')
    set_titletag('eXtension - Feeds')
    @communities = Community.find_all_sorted
  end

  def sitemap_index
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end
  
  def sitemap_communities
    @communities = Community.find(:all, :include => 'tags')
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end
  
  def sitemap_pages
    @article_links = Article.find(:all).collect{ |article| article.id_and_link }
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end

  def sitemap_faq
    @faq_ids = Faq.find(:all).collect{ |faq| faq.id }
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end
  
  def sitemap_events
    @event_ids = Event.find(:all).collect{ |event| event.id }
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end
     
  def articles
    @feed_title = 'Articles - eXtension'
    @feed_title = params[:categories].join(', ').capitalize+' '+@feed_title if params[:categories]
    @alternate_link = url_for(:controller => 'articles', :action => 'index', :only_path => false)
    gen_feed
  end
  
  def article
    @feed_title = 'Article - eXtension'
    @alternate_link = url_for(:controller => 'article', :action => 'index', :only_path => false)
    gen_feed
  end
  
  def community
    @feed_title = 'FAQs and Articles - eXtension'
    if !params[:categories] or (params[:categories] and params[:categories].empty?)
      flash[:notice] = 'No community was selected!'
      return redirect_to(:controller => 'feeds', :action => 'index')
    end
    
    tag = Tag.find_by_name(params[:categories][0])
    community = tag.content_community if tag
    
    # all that just to make sure the category is a community?  ugh.
    unless community
      flash[:notice] = 'The '+params[:categories][0]+' community does not exist.'
      return redirect_to(:controller => 'feeds', :action => 'index')
    end
    
    @feed_title = community.name.capitalize+' '+@feed_title
    @alternate_link = url_for(:controller => 'community', :action => 'index', :only_path => false)
    gen_feed(['faqs', 'articles'])
  end
  
  def all
    @feed_title = 'eXtension'
    @alternate_link = url_for(:controller => 'article', :action => 'index', :only_path => false)
    gen_feed
  end
  
  
  def events
    @feed_title = 'Events - eXtension'
    @feed_title = params[:categories].join(', ').capitalize+' '+@feed_title if params[:categories]
    @alternate_link = url_for(:controller => 'events', :action => 'index', :only_path => false)
    gen_feed
  end
  
  def faqs
    @feed_title = 'FAQs - eXtension'
    @alternate_link = url_for(:controller => 'faq', :action => 'index', :only_path => false)
    gen_feed
  end
  
  
  def gen_feed(type=params[:action])
    begin
      validate_gdata_params(params)
    rescue ArgumentError
      render_feed_error
      return
    end
    
    gdata_params = ['updated_min', 'updated_max', 'published_min',
                    'published_max', 'start-index', 'max-results',
                    'q', 'author', 'alt']
    
    start_index = 1
    max_results = 50
    q = nil
    author = nil
    alt = nil
    # eX content did not exist in published fashion prior to 10/2006.
    updated_min = Time.utc(2006,10)
    updated_max = Time.now.utc
    published_min = updated_min
    published_max = updated_max
    category_array = nil
    
    if params[:categories] && params[:categories].length > 0
      category_array = params[:categories]
      if category_array.length > 3
        raise ArgumentError
      end
    end
    
    begin
      gdata_params.each do |param|
        if params.has_key?(param)
          value = params[param]
          case param
            when 'q'
              raise ArgumentError
              
            when 'author'
              raise ArgumentError
              
            when 'alt'
              raise ArgumentError unless value == 'atom'
              
            when 'start-index'
              start_index = value
            
            when 'max-results'
              max_results = value
            
            when 'updated_min'
              updated_min = Time.parse(value)
            
            when 'updated_max'
              updated_max = Time.parse(value)
            
            when 'published_min'
              published_min = Time.parse(value)
            
            when 'published_max'
              published_max = Time.parse(value)
            
            when 'max_results'
              max_results = value
          end
        end
      end
    rescue ArgumentError
      render_feed_error
      return
    end
    
    if type=='all' || type.class == Array
      type = ['faqs', 'events', 'articles'] if type=='all'
      entries=[]
      total_possible_results = 0
      for content_type in type
        new_entries, new_possible_results = get_entries(content_type, category_array, updated_min, 
            updated_max, published_min, published_max, start_index, max_results)  
        entries.push(new_entries)
        total_possible_results+=new_possible_results
      end
      entries.flatten!.compact!
      entries.sort! {|x,y|
        x_date = x.send(x.class.default_ordering.split(" ")[0].split('.')[1])
        y_date = y.send(y.class.default_ordering.split(" ")[0].split('.')[1])
        y_date.to_time <=> x_date.to_time
      }
    else
      entries, total_possible_results = get_entries(type, category_array, updated_min, 
          updated_max, published_min, published_max, start_index, max_results)  
    end
    
    
    updated = entries.first.nil? ? Time.now.utc : entries.first.updated_at
    
    feed_meta = {:title => @feed_title, 
                 :subtitle => "eXtension published content",
                 :url => url_for(:only_path => false),
                 :alt_url => url_for(:only_path => false, :controller => 'main', :action => 'index'),
                 :total_results => total_possible_results.to_s,
                 :start_index => start_index.to_s,
                 :items_per_page => max_results.to_s,
                 :updated_at => updated}
    render_atom_feed_from(entries, feed_meta)

  end
  
  private 
  
  def get_entries(type, category_array, updated_min, updated_max, published_min, published_max, start_index, max_results)
    
    dpl_tag = Tag.find_by_name("dpl")
    
    alias_name='events' if type=='events'
    alias_name='articles' if type=='articles'
    alias_name='faqs' if type=='faqs'
    
    select = "SQL_CALC_FOUND_ROWS "+alias_name+".*"
    
    conditions = ['']
    conditions.first << alias_name+".updated_at >= ?"
    conditions.concat([updated_min])
    conditions.first << " and "+alias_name+".updated_at < ?"
    conditions.concat([updated_max])
    conditions.first << " and "+alias_name+".created_at >= ?"
    conditions.concat([published_min])
    conditions.first << " and "+alias_name+".created_at < ?"
    conditions.concat([published_max])
    
    joins = "as "+alias_name
     
    limit = "#{start_index - 1}, #{max_results - 1}"
    case type
      when 'faqs'
        if category_array
          entries = Faq.tagged_with_content_tags(category_array).ordered.limit(limit).
                      find(:all, :select => select, :conditions => conditions)
        else
          entries = Faq.ordered("faqs.heureka_published_at DESC").limit(limit).find(:all, :select => select,
                        :joins => joins,
                        :conditions => conditions)
        end
                        
      when 'articles'
        if category_array
          entries = Article.tagged_with_content_tags(category_array + ['!dpl']).ordered.limit(limit).find(:all, :select => select, :conditions => conditions)
        else
          entries = Article.tagged_with_content_tags('!dpl').ordered("articles.wiki_updated_at DESC").limit(limit).find(:all, :select => select, :joins => joins, :conditions => conditions)
        end  
              
      when 'events'
        if category_array
          entries = Event.tagged_with_content_tags(category_array).ordered.limit(limit).
                      find(:all, :select => select, :conditions => conditions)
        else
          entries = Event.ordered('events.date DESC').limit(limit).
                      find(:all, :select => select, :joins => joins, :conditions => conditions)
        end   
        
       end
      total_possible_results = ActiveRecord::Base.count_by_sql("SELECT FOUND_ROWS()")
      return entries, total_possible_results
    end
  
  def render_feed_error(status=400, msg='BAD REQUEST')
    @status = status.to_s + " " + msg
    render :template => 'feeds/status', :status => status, :layout => false
  end
  
  def establish_page_title_text  
    puts " accessing "+controller_name+"/"+action_name
    # this should be set in the controllers, but we set a sane default here  
    @page_title_text = session[:category] + " : " + params[:controller] + " : " + params[:action]
  end
end
