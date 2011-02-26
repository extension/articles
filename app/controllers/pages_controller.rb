# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class PagesController < ApplicationController
  before_filter :set_content_tag_and_community_and_topic
  layout 'pubsite'
  
  def show
    # folks chop off the page name and expect the url to give them something
    if (!params[:id])
      redirect_to site_articles_url(with_content_tag?), :status=>301
      return
    end
    
    @right_sidebar_to_display = "empty_vessel"
    @page = Page.find_by_id(params[:id])
   
    
    if @page
      @published_content = true
    else
      return do_404
    end
    
    # redirect check
    if(!params[:title] or params[:title] != @page.url_title)
      redirect_to(page_url(:id => @page.id, :title => @page.url_title),:status => :moved_permanently)
    end

    # get the tags on this article that correspond to community content tags
    @page_content_tags = @page.tags.content_tags.reject{|t| Tag::CONTENTBLACKLIST.include?(t.name) }.compact
    @page_content_tag_names = @page_content_tags.map(&:name)
    @page_bucket_names = @page.content_buckets.map(&:name)
        
    if(!@page_content_tags.blank?)
      # is this article tagged with youth?
      @youth = true if @page_bucket_names.include?('youth')
      
      # news check to set the meta tags for noindex
      @published_content = false if (@page_bucket_names.include?('news') and !@page_bucket_names.include?('originalnews'))
      
      # noindex check to set the meta tags for noindex
      @published_content = false if @page_bucket_names.include?('noindex')
      
      # get the tags on this article that are content tags on communities
      @community_content_tags = (Tag.community_content_tags & @page_content_tags)
    
      if(!@community_content_tags.blank?)
        @sponsors = Sponsor.tagged_with_any_content_tags(@community_content_tags.map(&:name)).prioritized
        # loop through the list, and see if one of these matches my @community already
        # if so, use that, else, just use the first in the list
        use_content_tag = @community_content_tags.rand
        @community_content_tags.each do |community_content_tag|
          if(community_content_tag.content_community == @community)
            use_content_tag = community_content_tag
          end
        end
      
        @community = use_content_tag.content_community
        @in_this_section = Page.contents_for_content_tag({:content_tag => use_content_tag})  if @community
        @youth = true if @community and @community.topic and @community.topic.name == 'Youth'
      end
    end
    
    if @page_bucket_names.include?('news')
      set_title("#{@page.title} - eXtension News", "Check out the news from the land grant university in your area.")
      set_titletag("#{@page.title} - eXtension News")
    elsif @page_bucket_names.include?('learning lessons')
      set_title('Learning', "Don't just read. Learn.")
      set_titletag("#{@page.title} - eXtension Learning Lessons")
    else
      set_title("#{@page.title} - eXtension", "Articles from our resource area experts.")
      set_titletag("#{@page.title} - eXtension")
    end

    flash.now[:googleanalytics] = request.request_uri + "?" + @community_content_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.primary_content_tag_name }.join('+').gsub(' ','_') if @community_content_tags and @community_content_tags.length > 0
    
    flash.now[:googleanalyticsresourcearea] = @community_content_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.primary_content_tag_name }.first.gsub(' ','_') if @community_content_tags and @community_content_tags.length > 0
    
  end
  
  # def detail
  #   @right_sidebar_to_display = 'faq_navigation'
  #   @faq = Faq.find_by_id(params[:id])
  #   if @faq
  #     set_title("#{@faq.title}", "Frequently asked questions from our resource area experts.")
  #     set_titletag("#{@faq.title} - eXtension")
  #     @published_content = true
  #   else 
  #     @missing = "FAQ #{params[:id]}"
  #     do_404
  #     return
  #   end
  # 
  #   # get the tags on this faq that correspond to community content tags
  #   faq_content_tags = @faq.tags.content_tags
  #   if(!faq_content_tags.blank?)
  #     # is this article tagged with youth?
  #     @youth = true if faq_content_tags.map(&:name).include?('youth')
  #     
  #     # get the tags on this article that are content tags on communities
  #     @community_content_tags = (Tag.community_content_tags & faq_content_tags)
  #     
  #     @faq_public_tags = faq_content_tags
  #   
  #     if(!@community_content_tags.blank?)
  #       @sponsors = Sponsor.tagged_with_any_content_tags(@community_content_tags.map(&:name)).prioritized
  #       # loop through the list, and see if one of these matches my @community already
  #       # if so, use that, else, just use the first in the list
  #       use_content_tag = @community_content_tags.rand
  #       @community_content_tags.each do |community_content_tag|
  #         if(community_content_tag.content_community == @community)
  #           use_content_tag = community_content_tag
  #         end
  #       end
  #     
  #       @community = use_content_tag.content_community
  #       @in_this_section = Page.contents_for_content_tag({:content_tag => use_content_tag}) if @community
  #       @youth = true if @community and @community.topic and @community.topic.name == 'Youth'
  #     end
  #   end    
  # 
  #   flash.now[:googleanalytics] = request.request_uri + "?" + @community_content_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.primary_content_tag_name }.join('+').gsub(' ','_') if @community_content_tags and @community_content_tags.length > 0
  #   flash.now[:googleanalyticsresourcearea] = @community_content_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.primary_content_tag_name }.first.gsub(' ','_') if @community_content_tags and @community_content_tags.length > 0
  # end
  
  def articles
    # validate order
    return do_404 unless Page.orderings.has_value?(params[:order])
    
    set_title('Articles', "Don't just read. Learn.")
    if(!@content_tag.nil?)
      set_title("All articles tagged with \"#{@content_tag.name}\"", "Don't just read. Learn.")
      set_titletag("Articles - #{@content_tag.name} - eXtension")
      pages = Page.articles.tagged_with_content_tag(@content_tag.name).ordered(params[:order]).paginate(:page => params[:page])
    else
      set_titletag("Articles - all - eXtension")
      pages = Page.articles.ordered(params[:order]).paginate(:page => params[:page])
    end
    @youth = true if @topic and @topic.name == 'Youth'
    render :partial => 'shared/dataitems', :locals => { :items => pages }, :layout => true
  end
  
  
  def news
    # validate order
    return do_404 unless Page.orderings.has_value?(params[:order])
    set_title('News', "Check out the news from the land grant university in your area.")
    if(!@content_tag.nil?)
      set_titletag("News - #{@content_tag.name} - eXtension")
      pages = Page.news.tagged_with_content_tag(@content_tag.name).ordered(params[:order]).paginate(:page => params[:page])
    else
      set_titletag("News - all - eXtension")
      pages = Page.news.ordered(params[:order]).paginate(:page => params[:page])
    end    
    @youth = true if @topic and @topic.name == 'Youth'
    render :partial => 'shared/dataitems', :locals => { :items => pages }, :layout => true
  end
  
  def learning_lessons
    # validate order
    return do_404 unless Page.orderings.has_value?(params[:order])
    set_title('Learning Lessons', "Don't just read. Learn.")
    set_titletag('Learning Lessons - eXtension')
    if(!@content_tag.nil?)
      set_titletag("Learning Lessons - #{@content_tag.name} - eXtension")
      pages = Page.articles.bucketed_as('learning lessons').tagged_with_content_tag(@content_tag.name).ordered(params[:order]).paginate(:page => params[:page])
    else
      set_titletag("Learning Lessons - all - eXtension")
      pages = Page.articles.bucketed_as('learning lessons').ordered(params[:order]).paginate(:page => params[:page])
    end    
    @youth = true if @topic and @topic.name == 'Youth'
    render :partial => 'shared/dataitems', :locals => { :items => pages }, :layout => true
  end
  
  def faqs
    # validate ordering
    return do_404 unless Page.orderings.has_value?(params[:order])
    set_title('Answered Questions from Our Experts', "Frequently asked questions from our resource area experts.")
    if(!@content_tag.nil?)
      set_title("Questions tagged with \"#{@content_tag.name}\"", "Frequently asked questions from our resource area experts.")
      set_titletag("Answered Questions from Our Experts - #{@content_tag.name} - eXtension")      
      pages = Page.faqs.tagged_with_content_tag(@content_tag.name).ordered(params[:order]).paginate(:page => params[:page])
    else
      set_titletag('Answered Questions from Our Experts - all - eXtension')
      pages = Page.faqs.ordered(params[:order]).paginate(:page => params[:page])
    end  
    @youth = true if @topic and @topic.name == 'Youth'
    render :partial => 'shared/dataitems', :locals => { :items => pages }, :layout => true
  end
  
end