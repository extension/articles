# === COPYRIGHT:
# Copyright (c) 2005-2011 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
# see LICENSE file

class PageinfoController < ApplicationController
  before_filter :signin_optional
  before_filter :set_content_tag_and_community
  before_filter :www_store_location
  before_filter :turn_off_resource_areas
  layout 'frontporch'


  def find_by_source
    source_name = params[:source_name]
    source_id = params[:source_id]
    if(!source_name.blank? and !source_id.blank?)
      @page = Page.find_by_source_name_and_id(source_name,source_id)
      if(@page)
        return redirect_to pageinfo_page_url(:id => @page.id)
      else
        flash.now[:error] = "Unable to find a page with that source and node id"
      end
    end
  end

  def show
    @page = Page.find_by_id(params[:id])
    if(@page)
      @external_links = @page.links.external
      @image_links = @page.links.image
      @local_links = @page.links.local
      @internal_links = @page.links.internal
      @wanted_links = @page.links.unpublished

    end
  end

  def pagelinklist
    @filteredparameters = ParamsFilter.new([:content_tag,
                                            :content_types,
                                            {:onlybroken => :boolean},
                                            {:with_instant_survey_links => :boolean}],params)
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
      pagelist_scope = pagelist_scope.tagged_with(@content_tag.name)
    end

    sort_order = "pages.has_broken_links DESC,pages.source_updated_at DESC"
    if(@filteredparameters.onlybroken)
      if(@filteredparameters.with_instant_survey_links)
        @pages = pagelist_scope.broken_links.with_instant_survey_links.page(params[:page]).order(sort_order).per(100)
      else
        @pages = pagelist_scope.broken_links.page(params[:page]).order(sort_order).per(100)
      end
    else
      if(@filteredparameters.with_instant_survey_links)
        @pages = pagelist_scope.with_instant_survey_links.page(params[:page]).order(sort_order).per(100)
      else
        @pages = pagelist_scope.page(params[:page]).order(sort_order).per(100)
      end
    end
  end

  def pagelist
    @filteredparameters = ParamsFilter.new([:content_tag,:content_types,{:articlefilter => :string},{:download => :string}],params)
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
      pagelist_scope = pagelist_scope.tagged_with(@content_tag.name)
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
      when 'bio'
         @articlefilter = 'Bio'
         bucket = 'bio'
     end # case statement
     if(!bucket.nil?)
       pagelist_scope = pagelist_scope.bucketed_as(bucket)
     end
   end # @articlefilter.nil?


    if(isdownload)
      @pages = pagelist_scope.ordered
      content_types = (@filteredparameters.content_types.blank?) ? 'all' : @filteredparameters.content_types.join('+')
      csvfilename =  "#{content_types}_pages_for_tag_#{@content_tag.name}"
      return page_csvlist(@pages,csvfilename,@content_tag.name)
    else
      @pages = pagelist_scope.ordered.page(params[:page]).per(100)
    end
  end

  def page_csvlist(articlelist,filename,content_tag_name)
    @pages = articlelist
    @content_tag_name = content_tag_name
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename='+filename+'.csv'
    render(:template => 'pageinfo/page_csvlist', :layout => false)
  end

  def orphaned
    @filteredparameters = ParamsFilter.new([{:download => :string}],params)
    if(!@filteredparameters.download.nil? and @filteredparameters.download == 'csv')
      isdownload = true
    end

    if(isdownload)
      @pages = Page.orphaned_pages
      csvfilename =  "all_orphaned_pages"
      return page_csvlist(@pages,csvfilename,'orphaned')
    else
      @pages = Page.orphaned_pages
    end
  end

end
