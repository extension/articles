# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class PagesController < ApplicationController
  layout 'pubsite'
  before_filter :set_content_tag_and_community_and_topic
  before_filter :login_optional
  
  def redirect_article
    # folks chop off the page name and expect the url to give them something
    if not (params[:title] or params[:id])
      redirect_to site_articles_url(with_content_tag?), :status=>301
      return
    end
    
    # get the title out, find it, and redirect  
    if params[:title]
      raw_title_to_lookup = CGI.unescape(request.request_uri.gsub('/pages/', ''))
      # comes in double-escaped from apache to handle the infamous '?'
      raw_title_to_lookup = CGI.unescape(raw_title_to_lookup)
      # why is this?
      raw_title_to_lookup.gsub!('??.html', '?')
      
      # special handling for mediawiki-like "Categoy:bob" - style titles
      if raw_title_to_lookup =~ /Category\:(.+)/
        content_tag = $1.gsub(/_/, ' ')
        redirect_to category_tag_index_url(:content_tag => content_tag_url_display_name(content_tag)), :status=>301
        return
      end
      
      if raw_title_to_lookup =~ /\/print(\/)?$/
        print = true
        raw_title_to_lookup.gsub!(/\/print(\/)?$/, '')
      end
      
      # try and handle googlebot urls that have the page params on the end for redirection (new urls automatically handled)
      (title_to_lookup,blah) = raw_title_to_lookup.split(%r{(.+)\?})[1,2]
      if(!title_to_lookup)
        title_to_lookup = raw_title_to_lookup
      end
      
      @page = Page.find_by_legacy_title_from_url(title_to_lookup)       
    elsif(params[:id])
      if(params[:print])
        print = true
      end
      @page = Page.find_by_id(params[:id])
    end
    
    if @page
      if(print)
        redirect_to(print_page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      else
        redirect_to(page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      end
    else
      @missing = title_to_lookup
      do_404
      return
    end
  end
  
  def redirect_faq
    # folks chop off the page name and expect the url to give them something
    if (!params[:id])
      redirect_to site_faqs_url(with_content_tag?), :status=>301
      return
    end
    if(params[:print])
      print = true
    end
    @page = Page.faqs.find_by_migrated_id(params[:id])
    if @page
      if(print)
        redirect_to(print_page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      else
        redirect_to(page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      end
    else
      return do_404
    end
  end
  
  def redirect_event
    # folks chop off the page name and expect the url to give them something
    if (!params[:id])
      redirect_to site_events_url(with_content_tag?), :status=>301
      return
    end
    if(params[:print])
      print = true
    end
    @page = Page.events.find_by_migrated_id(params[:id])
    if @page
      if(print)
        redirect_to(print_page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      else
        redirect_to(page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      end
    else
      return do_404
    end    
  end
  
  
    
  def show
    # folks chop off the page name and expect the url to give them something
    if (!params[:id])
      redirect_to site_articles_url(with_content_tag?), :status=>301
      return
    end
    
    @page = Page.includes(:cached_tags).find_by_id(params[:id])
    if @page
      @published_content = true
    else
      return do_404
    end

    # redirect to learn
    if(@page.is_event?)
      return redirect_to(AppConfig.configtable['learn_site'],:status => :moved_permanently)
    end
    
    # set canonical_link
    @canonical_link = page_url(:id => @page.id, :title => @page.url_title)
   
    # special redirect check
    if(@page.is_special_page? and @special_page = SpecialPage.find_by_page_id(@page.id))
      return redirect_to(main_special_url(:path => @special_page.path),:status => :moved_permanently)
    end
      
    
    # redirect check
    if(!params[:title] or params[:title] != @page.url_title)
      return redirect_to(@canonical_link,:status => :moved_permanently)
    end
    
    

    # get the tags on this article that correspond to community content tags
    @page_content_tag_names = @page.cached_content_tag_names
    @page_bucket_names = @page.content_buckets.map(&:name)
        
    if(!@page_content_tag_names.blank?)
      # is this article tagged with youth?
      @youth = true if @page_bucket_names.include?('youth')
      
      # news check to set the meta tags for noindex
      @published_content = false if (@page.indexed == Page::NOT_INDEXED)
      
      # get the tags on this article that are content tags on communities
      @community_content_tag_names = @page.community_content_tag_names
    
      if(!@community_content_tag_names.blank?)
        @sponsors = Sponsor.tagged_with_any_content_tags(@community_content_tag_names).prioritized
        # loop through the list, and see if one of these matches my @community already
        # if so, use that, else, just use the first in the list
        use_content_tag_name = @community_content_tag_names.rand
        @community_content_tag_names.each do |community_content_tag_name|
          if(@community and @community.content_tag_names.include?(community_content_tag_name))
            use_content_tag_name = community_content_tag_name
          end
        end
      
        use_content_tag = Tag.find_by_name(use_content_tag_name)
        @community = use_content_tag.content_community
        @in_this_section = Page.contents_for_content_tag({:content_tag => use_content_tag})  if @community
        @youth = true if @community and @community.topic and @community.topic.name == 'Youth'
        
        @page_communities = []
        @community_content_tag_names.each do |tagname|
          if(tag = Tag.find_by_name(tagname))
            if(community = tag.content_community)
              @page_communities << community
            end
          end
        end
      end
    end
    
    if(@page.is_news?)
      set_title("#{@page.title} - eXtension News", "Check out the news from the land grant university in your area.")
      set_titletag("#{@page.title} - eXtension News")
    elsif(@page.is_faq?)
      set_title("#{@page.title}", "Frequently asked questions from our resource area experts.")
      set_titletag("#{@page.title} - eXtension")
    elsif(@page.is_event?)
      set_title("#{@page.title.titleize} - #{@page.event_start.utc.to_date.strftime("%B %d, %Y")} - eXtension Event",  @page.title.titleize)
      set_titletag("#{@page.title.titleize} - #{@page.event_start.utc.to_date.strftime("%B %d, %Y")} - eXtension Event")
    elsif @page_bucket_names.include?('learning lessons')
      set_title('Learning', "Don't just read. Learn.")
      set_titletag("#{@page.title} - eXtension Learning Lessons")
    else
      set_title("#{@page.title} - eXtension", "Articles from our resource area experts.")
      set_titletag("#{@page.title} - eXtension")
    end
    
    @ask_two_point_oh_form = AppConfig.configtable['ask_two_point_oh_form']
    
    if(!@community_content_tag_names.blank? and !@page_content_tag_names.blank?)
      flash.now[:googleanalytics] = @page.id_and_link(true,{:tags => @page_content_tag_names.join(',').gsub(' ','_'), :content_types => @page.datatype.downcase}) 
      flash.now[:googleanalyticsresourcearea] = @community_content_tag_names[0].gsub(' ','_')
      @community_content_tag_id = Category.find_by_name(@community_content_tag_names[0]).id
    end
    
    
    
  end
  
  def list
    @list_content = true # don't index this page

    @filteredparameters = ParamsFilter.new([:tags,{:content_types => {:default => 'articles,news,faqs,events'}},{:articlefilter => :string},:order],params)
    if(!@filteredparameters.order.nil?)
      # validate order
      return do_404 unless Page.orderings.has_value?(@filteredparameters.order)
      @order = @filteredparameters.order
    end
   
    # empty tags? - presume "all"
    if(@filteredparameters.tags.nil?)
       alltags = true
       content_tags = ['all']
    else
       taglist_operator = @filteredparameters._tags.taglist_operator     
       alltags = (@filteredparameters.tags.include?('all'))
       if(alltags)
         content_tags = ['all']
       else 
         content_tags = @filteredparameters.tags
       end
    end
    
    pagelist_scope = Page.scoped({})
    if(!alltags)   
      if(taglist_operator and taglist_operator == 'and')
        pagelist_scope = pagelist_scope.tagged_with_all_content_tags(content_tags)
      else
        pagelist_scope = pagelist_scope.tagged_with_any_content_tags(content_tags)
      end
    end
   
    if(@filteredparameters.content_types)
      content_type_conditions = Page.content_type_conditions(@filteredparameters.content_types,{:allevents => true})
      if(!content_type_conditions.blank?)
         pagelist_scope = pagelist_scope.where(content_type_conditions)
      end
    end
   
     if(!@filteredparameters.articlefilter.nil?)
      case @filteredparameters.articlefilter
      when 'all'
        @articlefilter = 'All'
      when 'feature'
        @articlefilter = 'Feature'
        bucket = 'feature'
      when 'learning lessons'
        @articlefilter = 'Learning Lesson'
        bucket = 'learning lessons'
      when 'contents'
        @articlefilter = 'Contents'
        bucket = 'contents'
      when 'homage'
        @articlefilter = 'Homage'
        bucket = 'homage'
      end # case statement
      if(!bucket.nil?)
        pagelist_scope = pagelist_scope.bucketed_as(bucket)
      end
    end # @articlefilter.nil?
   
   
    titletypes = @filteredparameters.content_types.map{|type| type.capitalize}.join(', ')
    if(!alltags)
      tagstring = content_tags.join(" #{taglist_operator} ")
      @page_title_text = "#{titletypes} tagged with #{tagstring}"
      @title_tag = "#{titletypes} - #{tagstring} - eXtension"
    else
      @page_title_text = titletypes
      @title_tag = "#{titletypes} - all - eXtension"
    end 
    @header_description = "Don't just read. Learn."
   
    if(@order)
      pagelist_scope = pagelist_scope.ordered(@order)
    else
      pagelist_scope = pagelist_scope.ordered
    end
    @pages = pagelist_scope.paginate(:page => params[:page], :per_page => 100)
    @youth = true if @topic and @topic.name == 'Youth'
   
  end 
  
 
  def articles
    if(!@content_tag.nil? and !canonicalized_category?(params[:content_tag]))
      return redirect_to(:action => params[:action],:content_tag => content_tag_url_display_name(params[:content_tag]), :status=>301)
    end
    
    @show_selector = true
    @list_content = true # don't index this page
    order = (params[:order].blank?) ? "source_updated_at DESC" : params[:order]
    # validate order
    return do_404 unless Page.orderings.has_value?(order)
    
    set_title('Articles', "Don't just read. Learn.")
    if(!@content_tag.nil?)
      set_title("All articles tagged with \"#{@content_tag.name}\"", "Don't just read. Learn.")
      set_titletag("Articles - #{@content_tag.name} - eXtension")
      @pages = Page.articles.tagged_with_content_tag(@content_tag.name).ordered(order).paginate(:page => params[:page])
    else
      set_titletag("Articles - all - eXtension")
      @pages = Page.articles.ordered(order).paginate(:page => params[:page])
    end
    @youth = true if @topic and @topic.name == 'Youth'
    render(:template => 'pages/list')
  end
  
  def news
    if(!@content_tag.nil? and !canonicalized_category?(params[:content_tag]))
      return redirect_to(:action => params[:action],:content_tag => content_tag_url_display_name(params[:content_tag]), :status=>301)
    end
    
    @show_selector = true
    @list_content = true # don't index this page
    order = (params[:order].blank?) ? "source_updated_at DESC" : params[:order]
    # validate order
    return do_404 unless Page.orderings.has_value?(order)
    
    set_title('News', "Check out the news from the land grant university in your area.")
    if(!@content_tag.nil?)
      set_title("All news tagged with \"#{@content_tag.name}\"", "Don't just read. Learn.")
      set_titletag("News - #{@content_tag.name} - eXtension")
      @pages = Page.news.tagged_with_content_tag(@content_tag.name).ordered(order).paginate(:page => params[:page])
    else
      set_titletag("News - all - eXtension")
      @pages = Page.news.ordered(order).paginate(:page => params[:page])
    end    
    @youth = true if @topic and @topic.name == 'Youth'
    render(:template => 'pages/list')
  end
  
  def learning_lessons
    if(!@content_tag.nil? and !canonicalized_category?(params[:content_tag]))
      return redirect_to(:action => params[:action],:content_tag => content_tag_url_display_name(params[:content_tag]), :status=>301)
    end
    
    @show_selector = true
    @list_content = true # don't index this page
    order = (params[:order].blank?) ? "source_updated_at DESC" : params[:order]
    # validate order
    return do_404 unless Page.orderings.has_value?(order)
    
    set_title('Learning Lessons', "Don't just read. Learn.")
    set_titletag('Learning Lessons - eXtension')
    if(!@content_tag.nil?)
      set_titletag("Learning Lessons - #{@content_tag.name} - eXtension")
      @pages = Page.articles.bucketed_as('learning lessons').tagged_with_content_tag(@content_tag.name).ordered(order).paginate(:page => params[:page])
    else
      set_titletag("Learning Lessons - all - eXtension")
      @pages = Page.articles.bucketed_as('learning lessons').ordered(order).paginate(:page => params[:page])
    end    
    @youth = true if @topic and @topic.name == 'Youth'
    render(:template => 'pages/list')
  end
  
  def faqs
    if(!@content_tag.nil? and !canonicalized_category?(params[:content_tag]))
      return redirect_to(:action => params[:action],:content_tag => content_tag_url_display_name(params[:content_tag]), :status=>301)
    end
    
    @show_selector = true
    @list_content = true # don't index this page
    order = (params[:order].blank?) ? "source_updated_at DESC" : params[:order]
    # validate order
    return do_404 unless Page.orderings.has_value?(order)
    
    set_title('Answered Questions from Our Experts', "Frequently asked questions from our resource area experts.")
    if(!@content_tag.nil?)
      set_title("Questions tagged with \"#{@content_tag.name}\"", "Frequently asked questions from our resource area experts.")
      set_titletag("Answered Questions from Our Experts - #{@content_tag.name} - eXtension")      
      @pages = Page.faqs.tagged_with_content_tag(@content_tag.name).ordered(order).paginate(:page => params[:page])
    else
      set_titletag('Answered Questions from Our Experts - all - eXtension')
      @pages = Page.faqs.ordered(order).paginate(:page => params[:page])
    end  
    @youth = true if @topic and @topic.name == 'Youth'
    render(:template => 'pages/list')
  end
  
  def events
    return redirect_to(AppConfig.configtable['learn_site'],:status => :moved_permanently)
  end
end