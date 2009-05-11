class AdvertisementsController < ApplicationController
  
  # ajax call to update the position of the ads relative to each other
  def update_positions
    params[:sortable_list].each_with_index do |id, position|
      ad = Advertisement.find(id)
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
    set_title('Manage Sponsors - Site Admin - eXtension', 'Images')
    set_titletag('Manage Sponsors - eXtension Site Admin')
    # @advertisements = Advertisement.paginate(:per_page => 8, :page => params[:page])
    @advertisements = Advertisement.find(:all, :order => 'position')
    @right_column = false
  end

  def show
    @advertisement = Advertisement.find(params[:id])
    @right_column = false
  end

  def new
    @advertisement = Advertisement.new
    @community_tags = Advertisement.tags.collect{|c| [c.name, c.id]}
    @assets =  Asset.find(:all)
    # TODO: remove assets from collection which are already assigned to advertisements?
    @right_column = false
  end

  def create
    @advertisement = Advertisement.new(params[:advertisement])
    if @advertisement.save
      flash[:notice] = 'Advertisement was successfully created and added to the bottom of the list. You can now arrange the display order if needed.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @advertisement = Advertisement.find(params[:id])
    @community_tags = Advertisement.tags.collect{|c| [c.name, c.id]}
    @community_tags.insert(0, ["", ""])
    @right_column = false
  end

  def update
    @advertisement = Advertisement.find(params[:id])
    if @advertisement.update_attributes(params[:advertisement])
      flash[:notice] = 'Advertisement was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Advertisement.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
    
end
