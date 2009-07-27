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
    set_titletag('Manage Sponsors - Pubsite Admin')
    @sponsors = Sponsor.find(:all, :order => 'position')
  end

  def show
    @sponsor = Sponsor.find(params[:id])
  end

  def new
    @sponsor = Sponsor.new
    @logos =  Logo.find(:all)
  end

  def create
    @sponsor = Sponsor.new(params[:sponsor])
    if @sponsor.save
      @sponsor.content_tag_names=(params['sponsor']['content_tag_names'])
      flash[:notice] = 'Sponsor was successfully created and added to the bottom of the list. You can now arrange the display order if needed.'
      redirect_to(admin_sponsors_url)
    else
      render(:action => 'new')
    end
  end

  def edit
    @sponsor = Sponsor.find(params[:id])
  end

  def update
    @sponsor = Sponsor.find(params[:id])
    if @sponsor.update_attributes(params[:sponsor])
      @sponsor.content_tag_names=(params['sponsor']['content_tag_names'])
      flash[:notice] = 'Sponsor was successfully updated.'
      redirect_to(admin_sponsors_url)
    else
      render(:action => 'edit')
    end
  end

  def destroy
    Sponsor.find(params[:id]).destroy
    flash[:notice] = 'Sponsor was successfully deleted.'
    redirect_to(admin_sponsors_url)
  end
    
end
