# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ArticlesController < ApplicationController
  before_filter :set_community_topic_and_content_tag
  
  def index
    # validate order
    return do_404 unless Article.orderings.has_value?(params[:order])
    
    set_title('Articles', "Don't just read. Learn.")
    if(!@content_tag.nil?)
      set_titletag("Articles - #{@content_tag.name} - eXtension")
      articles = Article.tagged_with_content_tag(@content_tag.name).ordered(params[:order]).paginate(:page => params[:page])
    else
      set_titletag("Articles - all - eXtension")
      articles = Article.all.ordered(params[:order]).paginate(:page => params[:page])
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
    
      if title_to_lookup =~ /Category\:(.+)/
        category = $1.gsub(/_/, ' ')
        redirect_to content_tag_index_url(with_content_tag?), :status=>301
        return
      end
    
      if title_to_lookup =~ /\/print(\/)?$/
        params[:print] = true
        title_to_lookup = title_to_lookup.gsub(/\/print(\/)?$/, '')
      end

      article = get_article_by_title(title_to_lookup)
    else
      # using find_by to avoid exception
      article = ExternalArticle.find_by_id(params[:id])
      # Resolve links so they point to extension.org content where possible
      if article and article.content.nil?
        article.resolve_links!
      end
      
    end
    
    if article
      @published_content = true
    else
      @missing = title_to_lookup
      do_404
      return
    end
    
    for tag in article.tags
      category = tag if !tag.content_community.nil?
      @youth = true if tag.name == 'youth'
    end

    # go through tags, get first one that has .community not nil
    if category
      @community = category.content_community
      @homage = Article.bucketed_as('homage').tagged_with_content_tag(category.name).ordered.first if @community
      @in_this_section = Article.bucketed_as('contents').tagged_with_content_tag(category.name).ordered.first if @community
      @youth = true if @community and @community.topic and @community.topic.name == 'Youth'
    end
    
    if article.tag_list.include? 'news'
      set_title("#{article.title} - eXtension News", "Check out the news from the land grant university in your area.")
      set_titletag("#{article.title} - eXtension News")
    elsif article.tag_list.include? 'learning lessons'
      set_title('Learning', "Don't just read. Learn.")
      set_titletag("#{article.title} - eXtension")
    else
      set_title("#{article.title} - eXtension", "Articles from our resource area experts.")
      set_titletag("#{article.title} - eXtension")
    end
    
    @community_tags = (Tag.community_content_tags & article.tags)
    @sponsors = Sponsor.tagged_with_any_content_tags(@community_tags.map(&:name)).prioritized
    
    flash.now[:googleanalytics] = request.request_uri + "?" + @community_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.primary_content_tag_name }.join('+').gsub(' ','_') if @community_tags and @community_tags.length > 0
    
    # Specify view since we want sub class (external articles) to go here too
    render :template => 'articles/page', :locals => { :article => article }
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