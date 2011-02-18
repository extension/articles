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
end