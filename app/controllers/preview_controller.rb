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
    
    @events_count = Event.tagged_with_content_tag(@content_tag.name).count
    @faqs_count = Faq.tagged_with_content_tag(@content_tag.name).count
    @articles_count =  Article.tagged_with_content_tag(@content_tag.name).count
    @features_count = Article.bucketed_as('feature').tagged_with_content_tag(@content_tag.name).count
    @news_count = Article.bucketed_as('news').tagged_with_content_tag(@content_tag.name).count
    @learning_lessons_count = Article.bucketed_as('learning lessons').tagged_with_content_tag(@content_tag.name).count
    @contents_count = Article.bucketed_as('contents').tagged_with_content_tag(@content_tag.name).count
    @homage_count = Article.bucketed_as('homage').tagged_with_content_tag(@content_tag.name).count
    @homage = Article.homage_for_content_tag({:content_tag => @content_tag})
    @learnmore_count = Article.bucketed_as('learn more').tagged_with_content_tag(@content_tag.name).count
    @learnmore = Article.learnmore_for_content_tag({:content_tag => @content_tag})

    @contents_page = Article.contents_for_content_tag({:content_tag => @content_tag})
      
    @expertise_category = Category.find_by_name(@content_tag.name)
    if(@expertise_category)
      @aae_expertise_count = User.experts_by_category(@expertise_category.id).count
      @aae_autorouting_count = User.experts_by_category(@expertise_category.id).auto_routers.count
    end
  end
  
  def articlelist
    @right_column = false
  
    if(!@content_tag.nil?)
      if(params[:articlefilter].nil?)
        @articles = Article.tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)
      else
        case params[:articlefilter]
        when 'news'
          @articlefilter = 'News'
          @articles = Article.bucketed_as('news').tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)
        when 'feature'
          @articlefilter = 'Feature'
          @articles = Article.bucketed_as('feature').tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)
        when 'learning lessons'
          @articlefilter = 'Learning Lesson'
          @articles = Article.bucketed_as('learning lessons').tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)
        when 'contents'
          @articlefilter = 'Contents'
          @articles = Article.bucketed_as('contents').tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)
        when 'homage'
          @articlefilter = 'Homage'
          @articles = Article.bucketed_as('homage').tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)
        when 'learn more'
          @articlefilter = 'Learn More'
          @articles = Article.bucketed_as('learn more').tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)         
        else
          @articlefilter = nil
          @articles = Article.tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)
        end
      end
    end
  end
  
  def faqlist
    @right_column = false
    if(!@content_tag.nil?)
      @faqs = Faq.tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)
    end
  end
  
  def eventlist
    @right_column = false
    if(!@content_tag.nil?)
      @events = Event.tagged_with_content_tag(@content_tag.name).paginate(:page => params[:page], :per_page => 100, :order => 'xcal_updated_at DESC')
    end
  end
  
  
  
  def expertlist
  end
    
  def showpage
    # force applocation to be preview
    @app_location_for_display = 'preview'

    @right_sidebar_to_display = "empty_vessel"

    # this works, but should give anyone reading this code heartburn
    title_to_lookup = CGI.unescape(request.request_uri.gsub('/preview/pages/', ''))
    title_to_lookup.gsub!(' ', '_')

    if title_to_lookup =~ /\/print(\/)?$/
      params[:print] = true
      title_to_lookup = title_to_lookup.gsub(/\/print(\/)?$/, '')
    end

    begin 
      @article =  PreviewArticle.new_from_extensionwiki_page(title_to_lookup)
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