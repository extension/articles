# === COPYRIGHT:
# Copyright (c) 2005-2009 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
# see LICENSE file

class PreviewController < ApplicationController
  before_filter :force_html_format
  before_filter :set_content_tag_and_community_and_topic
  before_filter :signin_optional

  layout 'frontporch'

  def index
    @right_column = false
    @communities =  PublishingCommunity.all(:order => 'name')
  end

  def content_tag
    @right_column = false

    if(@content_tag.nil?)
      return render(:template => '/preview/invalid_tag')
    end

    if(!canonicalized_category?(params[:content_tag]))
      return redirect_to preview_tag_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
    end


    if(@community.nil?)
      return render(:template => '/preview/invalid_tag')
    else
      @page_title = "Launch checklist for content tagged \"#{@content_tag.name}\" (#{@community.name})"
      @other_community_tag_names = @community.tag_names.reject{|name| name == @content_tag.name}
      # TODO: sponsor list?
    end

    @all_content_count = Page.tagged_with(@content_tag.name).all.count
    @faqs_count = Page.faqs.tagged_with(@content_tag.name).all.count
    @articles_count =  Page.articles.tagged_with(@content_tag.name).all.count
    @features_count = Page.articles.bucketed_as('feature').tagged_with(@content_tag.name).all.count
    @learning_lessons_count = Page.articles.bucketed_as('learning lessons').tagged_with(@content_tag.name).all.count
    @contents_count = Page.articles.bucketed_as('contents').tagged_with(@content_tag.name).all.count
    @homage_count = Page.articles.bucketed_as('homage').tagged_with(@content_tag.name).all.count
    @homage = @community.homage unless(@community.nil?)


    @articles_broken_count =  Page.articles.tagged_with(@content_tag.name).broken_links.all.count
    @faqs_broken_count =  Page.faqs.tagged_with(@content_tag.name).broken_links.all.count
    @instant_survey_count = Page.tagged_with(@content_tag.name).with_instant_survey_links.all.count



    @contents_page = Page.contents_for_content_tag({:content_tag => @content_tag})

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
      title_to_lookup = CGI.unescape(request.fullpath.gsub('/preview/pages/', ''))
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
    if(!@article.tags.nil?)
      @article_content_tags = @article.tags.reject{|t| Tag::CONTENTBLACKLIST.include?(t.name) }.compact
      @article_tag_names = @article_content_tags.map(&:name)
    else
      @article_content_tags = []
      @article_tag_names = []
    end

    if(!@article.content_buckets.nil?)
      @article_bucket_names = @article.content_buckets.map(&:name)
    else
      @article_bucket_names = []
    end

    if(!@article_content_tags.blank?)

      # get the tags on this article that are content tags on communities
      @community_tags = (Tag.community_tags & @article_content_tags)

      if(!@community_tags.blank?)
        @sponsors = Sponsor.tagged_with_any(@community_tags.map(&:name)).prioritized
        # loop through the list, and see if one of these matches my @community already
        # if so, use that, else, just use the first in the list
        use_content_tag = @community_tags.sample
        @community_tags.each do |community_content_tag|
          if(community_content_tag.content_community == @community)
            use_content_tag = community_content_tag
          end
        end

        @community = use_content_tag.content_community
        @in_this_section = Page.contents_for_content_tag({:content_tag => use_content_tag})  if @community
      end
    end

    set_title("#{@article.title}")
  end

end
