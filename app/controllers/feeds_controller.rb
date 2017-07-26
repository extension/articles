# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class FeedsController < ApplicationController
  skip_before_filter :personalize_location_and_institution, :except => :index
  layout 'frontporch'

  def index
    set_title('Feeds')
    set_title('eXtension - Feeds')
    @communities = PublishingCommunity.launched.all(:order => 'public_name')
  end

  def community
    return redirect_to(content_feed_url(:tags => params[:tags]), :status => 301)
  end

  def content
    request.format = 'xml'
    filteredparameters_list = [:max_results,
                               {:limit => {:default => Settings.default_feed_content_limit}},
                               :tags,
                               {:content_types => {:default => 'articles,faqs'}}]
    filteredparams = ParamsFilter.new(filteredparameters_list,params)


    if(!filteredparams.max_results.nil?)
      limit = filteredparams.max_results
    else
      limit = filteredparams.limit
    end

    if(limit > Settings.max_feed_content_limit)
      limit = Settings.max_feed_content_limit
    end

    # empty tags? - presume "all"
    if(filteredparams.tags.nil?)
       alltags = true
       content_tags = ['all']
    else
       tag_operator = filteredparams._tags.taglist_operator
       alltags = (filteredparams.tags.include?('all'))
       if(alltags)
         content_tags = ['all']
       else
         content_tags = filteredparams.tags
       end
    end

    datatypes = []
    filteredparams.content_types.each do |content_type|
      case content_type
      when 'faqs'
        datatypes << 'Faq'
      when 'articles'
        datatypes << 'Article'
      end
    end

    if(alltags)
       @pages = Page.recent_content(:datatypes => datatypes, :limit => limit)
    else
       @pages = Page.recent_content(:datatypes => datatypes, :content_tags => content_tags, :limit => limit, :tag_operator => tag_operator, :within_days => Settings.events_within_days)
    end

    @id = "tag:#{request.host},#{Time.now.year}:#{request.path}"
    @title = "eXtension #{filteredparams.content_types.map{|name| name.capitalize}.join(',')}"
    if(alltags)
      @title += "- All"
    else
      @title += "- " + content_tags.join(" #{filteredparams._tags.taglist_operator} ")
    end

    @subtitle = "eXtension published content"
    @updated_at = @pages.blank? ? Time.zone.now : @pages.first.updated_at
    respond_to do |format|
      format.xml { render(:layout => false, template: 'feeds/pages', :content_type => "application/atom+xml") }
    end
  end

end
