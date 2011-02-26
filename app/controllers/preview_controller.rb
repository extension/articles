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
    @articles_count =  Page.bucketed_as('notnews').tagged_with_content_tag(@content_tag.name).count
    @features_count = Page.bucketed_as('feature').tagged_with_content_tag(@content_tag.name).count
    @news_count = Page.bucketed_as('news').tagged_with_content_tag(@content_tag.name).count
    @learning_lessons_count = Page.bucketed_as('learning lessons').tagged_with_content_tag(@content_tag.name).count
    @contents_count = Page.bucketed_as('contents').tagged_with_content_tag(@content_tag.name).count
    @homage_count = Page.bucketed_as('homage').tagged_with_content_tag(@content_tag.name).count
    @homage = @community.homage

    @articles_broken_count =  Page.bucketed_as('notnews').tagged_with_content_tag(@content_tag.name).broken_links.count

    @contents_page = Page.contents_for_content_tag({:content_tag => @content_tag})
      
    @expertise_category = Category.find_by_name(@content_tag.name)
    if(@expertise_category)
      @aae_expertise_count = User.experts_by_category(@expertise_category.id).count
      @aae_autorouting_count = User.experts_by_category(@expertise_category.id).auto_routers.count
    end
  end
  
  
  def articlelist
    @filteredparameters = ParamsFilter.new([:content_tag,{:download => :string},{:articlefilter => :string}],params)
    @right_column = false
    if(!@filteredparameters.content_tag? or @filteredparameters.content_tag.nil?)
      # fake content tag for display purposes
      @content_tag = Tag.new(:name => 'all')
    else
      @content_tag = @filteredparameters.content_tag
    end
      

    if(!@filteredparameters.download.nil? and @filteredparameters.download == 'csv')
      isdownload = true
    end
    
    # sets @articles and @articlefilter
    articles_list_scope = get_articles_for_listing({:content_tag => @filteredparameters.content_tag,
                                                    :articlefilter => @filteredparameters.articlefilter})
                                                     
                               
                              
                              
    
    if(isdownload)
      @articles = articles_list_scope.ordered
      article_type = (@articlefilter.blank?) ? 'all' : @articlefilter.downcase 
      csvfilename =  "#{article_type}_articles_for_tag_#{@content_tag.name}"
      return article_csvlist(@articles,csvfilename,@content_tag)
    else
      @articles = articles_list_scope.ordered.paginate(:page => params[:page], :per_page => 100)
    end
        
  end
  
  def articlelinklist
    @filteredparameters = ParamsFilter.new([:content_tag,{:articlefilter => :string},{:onlybroken => :boolean}],params)
    @right_column = false
    if(!@filteredparameters.content_tag? or @filteredparameters.content_tag.nil?)
      # fake content tag for display purposes
      @content_tag = Tag.new(:name => 'all')
    else
      @content_tag = @filteredparameters.content_tag
    end
    
    # sets @articlefilter
    articles_list_scope = get_articles_for_listing({:content_tag => @filteredparameters.content_tag,
                                          :articlefilter => @filteredparameters.articlefilter})
                                          
    sort_order = "articles.has_broken_links DESC,articles.source_updated_at DESC"
    if(@filteredparameters.onlybroken)
      @articles = articles_list_scope.broken_links.paginate(:page => params[:page], :per_page => 100, :order => sort_order)
    else
      @articles = articles_list_scope.paginate(:page => params[:page], :per_page => 100, :order => sort_order)
    end
  end
  
  def articlelinks
    @right_column = false
    @article = Page.find_by_id(params[:id])
    if(@article)
      @external_links = @article.content_links.external
      @local_links = @article.content_links.local
      @internal_links = @article.content_links.internal
      @wanted_links = @article.content_links.unpublished
    end
  end
  
  def faqlist
    @right_column = false
    if(!@content_tag.nil?)
      if(!params[:download].nil? and params[:download] == 'csv')
        @faqs = Faq.tagged_with_content_tag(@content_tag.name).ordered
        csvfilename =  "faqs_for_tag_#{@content_tag.name}"
        return faq_csvlist(@faqs,csvfilename,@content_tag)
      else
        @faqs = Faq.tagged_with_content_tag(@content_tag.name).ordered.paginate(:page => params[:page], :per_page => 100)
      end
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
  
  def showcategory
    # force applocation to be preview
    @app_location_for_display = 'preview'
    @right_sidebar_to_display = "empty_vessel"
    @category_string = params[:categorystring]
  end
    
    
    
  def showpage
    if(params[:title].blank?)
      return(redirect_to(preview_home_url))
    end
    
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
      @article =  PreviewPage.new_from_extensionwiki_page(title_to_lookup)
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
  
  def article_csvlist(articlelist,filename,content_tag)
    @articles = articlelist
    @content_tag = content_tag
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename='+filename+'.csv'
    render(:template => 'preview/article_csvlist', :layout => false)
  end
  
  def faq_csvlist(faqlist,filename,content_tag)
    @faqs = faqlist
    @content_tag = content_tag
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename='+filename+'.csv'
    render(:template => 'preview/faq_csvlist', :layout => false)
  end

  private
  
  def get_articles_for_listing(options = {})
    paginate_list = options[:paginate_list]
    content_tag = options[:content_tag]
    articlefilter = options[:articlefilter]
    
    if(articlefilter.nil?)
       bucket = 'notnews'
       @articlefilter = nil
     else
       case articlefilter
       when 'all'
         @articlefilter = 'All'
         bucket = nil
       when 'news'
         @articlefilter = 'News'
         bucket = 'news'
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
       when 'learn more'
         @articlefilter = 'Learn More'
         bucket = 'learn more'
       else
         @articlefilter = nil
         bucket = 'notnews'
       end # case statement
     end # articlefilter.nil?
     
     # build the scope
     articles_list_scope = Page.scoped({})
     if(bucket)
       articles_list_scope = articles_list_scope.bucketed_as(bucket)
     end
     if(content_tag)
       articles_list_scope = articles_list_scope.tagged_with_content_tag(content_tag.name)
     end
     articles_list_scope
  end
  
end