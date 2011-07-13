# === COPYRIGHT:
# Copyright (c) 2005-2009 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class PreviewController < ApplicationController
  before_filter :login_optional
  before_filter :set_content_tag_and_community_and_topic
  
  layout 'pubsite'

  def index
    @right_column = false
    @approved_communities =  Community.approved.all(:order => 'name')
    @other_public_communities = Community.usercontributed.public_list.all(:order => 'name')
  end
  
  def content_tag
    @right_column = false
    
    if(@content_tag.nil?)
      return render(:template => 'preview/invalid_tag')
    end
    
    if(!canonicalized_category?(params[:content_tag]))
      return redirect_to preview_tag_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
    end
    
    
    if(@community.nil?)
      @title_tag = "eXtension Content Checklist for tag: #{@content_tag}"
      # youth styling
      @youth = true if @content_tag.name == 'youth'
    else
      @title_tag = "Launch checklist for content tagged \"#{@content_tag.name}\" (#{@community.name})"
      # youth styling
      @youth = true if @topic and @topic.name == 'Youth'
      @other_community_content_tag_names = @community.cached_content_tags(true).reject{|name| name == @content_tag.name}
      # TODO: sponsor list?
    end
    
    @all_content_count = Page.tagged_with_content_tag(@content_tag.name).count
    @events_count = Page.events.tagged_with_content_tag(@content_tag.name).count
    @faqs_count = Page.faqs.tagged_with_content_tag(@content_tag.name).count
    @articles_count =  Page.articles.tagged_with_content_tag(@content_tag.name).count
    @features_count = Page.newsicles.bucketed_as('feature').tagged_with_content_tag(@content_tag.name).count
    @news_count = Page.news.tagged_with_content_tag(@content_tag.name).count
    @learning_lessons_count = Page.articles.bucketed_as('learning lessons').tagged_with_content_tag(@content_tag.name).count
    @contents_count = Page.articles.bucketed_as('contents').tagged_with_content_tag(@content_tag.name).count
    @homage_count = Page.articles.bucketed_as('homage').tagged_with_content_tag(@content_tag.name).count
    @homage = @community.homage

    @articles_broken_count =  Page.articles.tagged_with_content_tag(@content_tag.name).broken_links.count
    @faqs_broken_count =  Page.faqs.tagged_with_content_tag(@content_tag.name).broken_links.count
    @events_broken_count =  Page.events.tagged_with_content_tag(@content_tag.name).broken_links.count
    @news_broken_count =  Page.news.tagged_with_content_tag(@content_tag.name).broken_links.count
    @all_broken_count = Page.tagged_with_content_tag(@content_tag.name).broken_links.count

    @contents_page = Page.contents_for_content_tag({:content_tag => @content_tag})
      
    @expertise_category = Category.find_by_name(@content_tag.name)
    if(@expertise_category)
      @aae_expertise_count = User.experts_by_category(@expertise_category.id).count
      @aae_autorouting_count = User.experts_by_category(@expertise_category.id).auto_routers.count
    end
  end
        
  def expertlist
  end
  
  def showcategory
    # force applocation to be preview
    @app_location_for_display = 'preview'
    @right_sidebar_to_display = "empty_vessel"
    @category_string = params[:categorystring]
  end
    
    
    
  def showpage
    if((params[:source].blank? or params[:source_id].blank?) and params[:title].blank?)
      return(redirect_to(preview_home_url))
    end
    
    # force applocation to be preview
    @app_location_for_display = 'preview'
    @right_sidebar_to_display = "empty_vessel"
    
    source = params[:source] || 'copwiki'
    source_id = params[:source_id] || ''
    
    if(!params[:title].blank?)
      # got here via /preview/pages/title for handling wiki titles
      # so we can't use the title param - we have to use the request_uri because of
      # the infamous question mark articles      
      title_to_lookup = CGI.unescape(request.request_uri.gsub('/preview/pages/', ''))
      title_to_lookup.gsub!(' ', '_')
      source_id = title_to_lookup
    end
      

    begin 
      @article =  PreviewPage.new_from_source(source,source_id)
    rescue ContentRetrievalError => exception
      @missing = title_to_lookup
      @missing_message = "Preview Page Retrieval failed, reason:<br/> #{exception.message}"
      return do_404
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
      @community_content_tags = (Tag.community_content_tags & @article_content_tags)

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