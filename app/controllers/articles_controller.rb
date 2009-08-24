# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ArticlesController < ApplicationController
  before_filter :set_content_tag_and_community_and_topic
  
  def index
    # validate order
    return do_404 unless Article.orderings.has_value?(params[:order])
    
    set_title('Articles', "Don't just read. Learn.")
    if(!@content_tag.nil?)
      set_titletag("Articles - #{@content_tag.name} - eXtension")
      articles = Article.tagged_with_content_tag(@content_tag.name).ordered(params[:order]).paginate(:page => params[:page])
    else
      set_titletag("Articles - all - eXtension")
      articles = Article.ordered(params[:order]).paginate(:page => params[:page])
    end
    @youth = true if @topic and @topic.name == 'Youth'
    render :partial => 'shared/dataitems', :locals => { :items => articles, :klass => Article }, :layout => true
  end
  
  def page
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
      title_to_lookup = CGI.unescape(request.request_uri.gsub('/pages/', ''))
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

      @article = get_article_by_title(title_to_lookup)
    else
      # using find_by to avoid exception
      @article = Article.find_by_id(params[:id])
      # Resolve links so they point to extension.org content where possible
      if @article and @article.content.nil?
        @article.resolve_links!
      end
      
    end
    
    if @article
      @published_content = true
    else
      @missing = title_to_lookup
      do_404
      return
    end


    # get the tags on this article that correspond to community content tags
    @article_content_tags = @article.tags.content_tags.reject{|t| Tag::CONTENTBLACKLIST.include?(t.name) }.compact
    @article_content_tag_names = @article_content_tags.map(&:name)
    if(!@article_content_tags.blank?)
      # is this article tagged with youth?
      @youth = true if @article_content_tag_names.include?('youth')
      
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
    
    if @article_content_tag_names.include?('news')
      set_title("#{@article.title} - eXtension News", "Check out the news from the land grant university in your area.")
      set_titletag("#{@article.title} - eXtension News")
    elsif @article_content_tag_names.include?('learning lessons')
      set_title('Learning', "Don't just read. Learn.")
      set_titletag("#{@article.title} - eXtension")
    else
      set_title("#{@article.title} - eXtension", "Articles from our resource area experts.")
      set_titletag("#{@article.title} - eXtension")
    end

    
    flash.now[:googleanalytics] = request.request_uri + "?" + @community_content_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.primary_content_tag_name }.join('+').gsub(' ','_') if @community_content_tags and @community_content_tags.length > 0
    
    # Specify view since we want sub class (external articles) to go here too
    #render :template => 'articles/page', :locals => { :article => article }
  end
  
  def news
    # validate order
    return do_404 unless Article.orderings.has_value?(params[:order])
    set_title('News', "Check out the news from the land grant university in your area.")
    if(!@content_tag.nil?)
      set_titletag("News - #{@content_tag.name} - eXtension")
      articles = Article.bucketed_as('news').tagged_with_content_tag(@content_tag.name).ordered(params[:order]).paginate(:page => params[:page])
    else
      set_titletag("News - all - eXtension")
      articles = Article.bucketed_as('news').ordered(params[:order]).paginate(:page => params[:page])
    end    
    @youth = true if @topic and @topic.name == 'Youth'
    render :partial => 'shared/dataitems', :locals => { :items => articles, :klass => Article }, :layout => true
  end
 
  def learning_lessons
    # validate order
    return do_404 unless Article.orderings.has_value?(params[:order])
    set_title('Learning Lessons', "Don't just read. Learn.")
    set_titletag('Learning Lessons - eXtension')
    if(!@content_tag.nil?)
      set_titletag("Learning Lessons - #{@content_tag.name} - eXtension")
      articles = Article.bucketed_as('learning lessons').tagged_with_content_tag(@content_tag.name).ordered(params[:order]).paginate(:page => params[:page])
    else
      set_titletag("Learning Lessons - all - eXtension")
      articles = Article.bucketed_as('learning lessons').ordered(params[:order]).paginate(:page => params[:page])
    end    
    @youth = true if @topic and @topic.name == 'Youth'
    render :partial => 'shared/dataitems', :locals => { :items => articles, :klass => Article }, :layout => true
  end
    
  private
  
  def get_article_by_title(title_to_lookup)
    @article_by_title ||= Article.find_by_title_url(title_to_lookup)
  end

  def get_class
    @class = Article
  end
  
end