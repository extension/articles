# === COPYRIGHT:
# Copyright (c) 2005-2011 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class PageinfoController < ApplicationController
  before_filter :login_optional
  before_filter :set_content_tag_and_community_and_topic
  layout 'pubsite'
  
  
  def find_by_source
    @right_column = false
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
    @right_column = false
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
  
  def page_csvlist(articlelist,filename,content_tag)
    @pages = articlelist
    @content_tag = content_tag
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename='+filename+'.csv'
    render(:template => 'pageinfo/page_csvlist', :layout => false)
  end
  
end