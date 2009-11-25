# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class PreviewController < ApplicationController
  before_filter :login_optional
  before_filter :set_content_tag_and_community_and_topic
  
  def override_app_location
    @app_location_for_display = 'preview'
  end
  
  def index
    
  end
  
  def community
    if(@community.nil?)
      return render(:template => 'preview/nocommunity')
    end
    @title_tag = "#{@community.name} - eXtension Content Checklist"
  end
  
  def showpage
    override_app_location
    
    # folks chop off the page name and expect the url to give them something
    if not (params[:title] or params[:id])
      redirect_to site_articles_url(with_content_tag?), :status=>301
      return
    end
    
    @right_sidebar_to_display = "empty_vessel"
    
    if params[:title]
      #ActiveRecord::Base::logger.info "article#page:  title = #{params[:title].inspect}"
      #ActiveRecord::Base::logger.info "article#page:  request_uri = #{request.request_uri.inspect}"
      # ideally, rails would include a lone '?' at the end of a url...
      # yeah, poor form, but such is life with the wiki
    
      # this does not work...but did work at one time
      #title_to_lookup = params[:title].to_s
      # this works, but should give anyone reading this code heartburn
      title_to_lookup = CGI.unescape(request.request_uri.gsub('/preview/pages/', ''))
      # comes in double-escaped from apache to handle the infamous '?'
      title_to_lookup = CGI.unescape(title_to_lookup)
      # why is this?
      title_to_lookup = title_to_lookup.gsub('??.html', '?')
    
      if title_to_lookup =~ /\s+/
        redirect_to wiki_page_url(title_to_lookup.gsub(' ', '_')), :status=>301
        return
      end
    
      # special handling for mediawiki-like "Categoy:bob" - style titles
      if title_to_lookup =~ /Category\:(.+)/
        content_tag = $1.gsub(/_/, ' ')
        redirect_to content_tag_index_url(:content_tag => content_tag), :status=>301
        return
      end
    
      if title_to_lookup =~ /\/print(\/)?$/
        params[:print] = true
        title_to_lookup = title_to_lookup.gsub(/\/print(\/)?$/, '')
      end

      @article =  PreviewArticle.new_from_extensionwiki_page(title_to_lookup)
    else
      # # using find_by to avoid exception
      # @article = Article.find_by_id(params[:id])
      # # Resolve links so they point to extension.org content where possible
      # if @article and @article.content.nil?
      #   @article.resolve_links!
      # end
      do_404
      return
    end
    
    if @article
      @published_content = true
    else
      @missing = title_to_lookup
      do_404
      return
    end

    # get the tags on this article that correspond to community content tags
    if(!@article.content_tags.nil?)
      @article_content_tags = @article.content_tags.reject{|t| Tag::CONTENTBLACKLIST.include?(t.name) }.compact
      @article_content_tag_names = @article_content_tags.map(&:name)
    else
      @article_content_tags = []
      @article_content_tag_names = []
    end
    
    if(!@article.content_buckets.nil?)
      @article_bucket_names = @article.content_buckets.map(&:name)
    else
      @article_bucket_names = []
    end
    
    if(!@article_content_tags.blank?)
      # is this article tagged with youth?
      @youth = true if @article_bucket_names.include?('youth')
      
      # get the tags on this article that are content tags on communities
      @community_content_tags = (Tag.community_content_tags({:launchedonly => true}) & @article_content_tags)
    
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
        @homage = Article.homage_for_content_tag({:content_tag => use_content_tag}) if @community
        @in_this_section = Article.contents_for_content_tag({:content_tag => use_content_tag})  if @community
        @youth = true if @community and @community.topic and @community.topic.name == 'Youth'
      end
    end
    
    if @article_bucket_names.include?('news')
      set_title("#{@article.title} - eXtension News", "Check out the news from the land grant university in your area.")
      set_titletag("#{@article.title} - eXtension News")
    elsif @article_bucket_names.include?('learning lessons')
      set_title('Learning', "Don't just read. Learn.")
      set_titletag("#{@article.title} - eXtension Learning Lessons")
    else
      set_title("#{@article.title} - eXtension", "Articles from our resource area experts.")
      set_titletag("#{@article.title} - eXtension")
    end

   end

  
end