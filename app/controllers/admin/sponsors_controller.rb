# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Admin::SponsorsController < ApplicationController
  before_filter :admin_required
  before_filter :check_purgatory
  before_filter :turn_off_right_column
  
  
  # ajax call to update the position of the ads relative to each other
  def update_positions
    params[:sortable_list].each_with_index do |id, position|
      ad = Sponsor.find(id)
      ad.update_attribute(:position, (position + 1))  
    end
    render :nothing => true
  end
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    set_titletag('Manage Sponsors - Pubsite Admin')
    @sponsors = Sponsor.find(:all, :order => 'position')
  end

  def show
    @sponsor = Sponsor.find(params[:id])
  end

  def new
    @sponsor = Sponsor.new
    @community_tags = Sponsor.tags.collect{|c| [c.name, c.id]}
    @assets =  Asset.find(:all)
    # TODO: remove assets from collection which are already assigned to advertisements?
  end

  def create
    @sponsor = Sponsor.new(params[:sponsor])
    if @sponsor.save
      flash[:notice] = 'Sponsor was successfully created and added to the bottom of the list. You can now arrange the display order if needed.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @sponsor = Sponsor.find(params[:id])
    @community_tags = Sponsor.tags.collect{|c| [c.name, c.id]}
    @community_tags.insert(0, ["", ""])
  end

  def update
    @sponsor = Sponsor.find(params[:id])
    if @sponsor.update_attributes(params[:sponsor])
      flash[:notice] = 'Sponsor was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Sponsor.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
    
end
