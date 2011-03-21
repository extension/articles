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
  
  
  def pagelist
    @filteredparameters = ParamsFilter.new([:content_tag,:content_types,{:articlefilter => :string},{:download => :string}],params)
    @right_column = false
    if(!@filteredparameters.content_tag? or @filteredparameters.content_tag.nil?)
      # fake content tag for display purposes
      @content_tag = Tag.new(:name => 'all')
    else
      @content_tag = @filteredparameters.content_tag
    end
    @articlefilter = @filteredparameters.articlefilter
      

    if(!@filteredparameters.download.nil? and @filteredparameters.download == 'csv')
      isdownload = true
    end
    
    # build the scope
    pagelist_scope = Page.scoped({})
    if(@filteredparameters.content_types)
      content_type_conditions = Page.content_type_conditions(@filteredparameters.content_types,{:allevents => true})
      if(!content_type_conditions.blank?)
         pagelist_scope = pagelist_scope.where(content_type_conditions)
      end
    end
    
    if(@content_tag)
      pagelist_scope = pagelist_scope.tagged_with_content_tag(@content_tag.name)
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
    

    if(isdownload)
      @pages = pagelist_scope.ordered
      content_types = (@filteredparameters.content_types.blank?) ? 'all' : @filteredparameters.content_types.join('+')
      csvfilename =  "#{content_types}_pages_for_tag_#{@content_tag.name}"
      return page_csvlist(@pages,csvfilename,@content_tag)
    else
      @pages = pagelist_scope.ordered.paginate(:page => params[:page], :per_page => 100)
    end
  end
  
  def pagelinklist
    @filteredparameters = ParamsFilter.new([:content_tag,:content_types,{:onlybroken => :boolean}],params)
    @right_column = false
    if(!@filteredparameters.content_tag? or @filteredparameters.content_tag.nil?)
      # fake content tag for display purposes
      @content_tag = Tag.new(:name => 'all')
    else
      @content_tag = @filteredparameters.content_tag
    end
    
    # build the scope
    pagelist_scope = Page.scoped({})
    if(@filteredparameters.content_types)
      content_type_conditions = Page.content_type_conditions(@filteredparameters.content_types,{:allevents => true})
      if(!content_type_conditions.blank?)
         pagelist_scope = pagelist_scope.where(content_type_conditions)
      end
    end
    
    if(@content_tag)
      pagelist_scope = pagelist_scope.tagged_with_content_tag(@content_tag.name)
    end

                                          
    sort_order = "pages.has_broken_links DESC,pages.source_updated_at DESC"
    if(@filteredparameters.onlybroken)
      @pages = pagelist_scope.broken_links.paginate(:page => params[:page], :per_page => 100, :order => sort_order)
    else
      @pages = pagelist_scope.paginate(:page => params[:page], :per_page => 100, :order => sort_order)
    end
  end
  
  def pagelinks
    @right_column = false
    @page = Page.find_by_id(params[:id])
    if(@page)
      @external_links = @page.links.external
      @local_links = @page.links.local
      @internal_links = @page.links.internal
      @wanted_links = @page.links.unpublished
    end
  end
  
  def pageinfo
    @right_column = false
    @page = Page.find_by_id(params[:id])
    if(@page)
      @external_links = @page.links.external
      @local_links = @page.links.local
      @internal_links = @page.links.internal
      @wanted_links = @page.links.unpublished
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
      @article =  PreviewPage.new_from_source('copwiki',title_to_lookup)
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
  
  def page_csvlist(articlelist,filename,content_tag)
    @pages = articlelist
    @content_tag = content_tag
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename='+filename+'.csv'
    render(:template => 'preview/page_csvlist', :layout => false)
  end
  
  

  
end