class AssetsController < ApplicationController
    
  # and these aren't registered by default....why?
  Mime::Type.register("image/gif", :gif)
  Mime::Type.register("image/jpg", :jpg)
  Mime::Type.register("image/png", :png)
  
  # GET /assets
  # GET /assets.xml
  def index
    set_titletag('Manage Advertising Graphics - Pubsite Admin')
    @assets = Asset.find(:all, :conditions => { :parent_id => nil }, :order => 'created_at DESC')
    @right_column = false
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @assets.to_xml }
    end
  end

  # GET /assets/1
  # GET /assets/1.xml
  def show
    @asset = Asset.find_by_filename(params[:file].to_s + "." + params[:format].to_s)
    @asset = Asset.find(params[:file]) unless @asset
    show_thumbnail = (params[:thumb] == "true")
    respond_to do |format|
      format.html { render :action => 'show', :layout => false }
      format.xml  { render :xml => @asset.to_xml }
      format.jpg  { send_data(@asset.image_data(show_thumbnail), 
                              :type  => @asset.content_type, 
                              :filename => @asset.filename, 
                              :disposition => 'inline') }
      format.gif  { send_data(@asset.image_data(show_thumbnail), 
                              :type  => @asset.content_type, 
                              :filename => @asset.filename, 
                              :disposition => 'inline') }
      format.png  { send_data(@asset.image_data(show_thumbnail), 
                              :type  => @asset.content_type, 
                              :filename => @asset.filename, 
                              :disposition => 'inline') }
    end
  rescue Exception => err
    logger.debug(err.message)
    logger.debug(err.backtrace)
    
    file = "#{RAILS_ROOT}/public/images/loading.gif"
    data = File.new(file, 'r').read
    send_data(data, :filename => "unknown.gif", :type => "image/gif", :disposition => 'inline')
  end

  # GET /assets/new
  def new
    @asset = Asset.new
  end

  # # GET /assets/1;edit
  # def edit
  #   @asset = Asset.find(params[:id])
  # end

  # POST /assets
  # POST /assets.xml
  def create
    @asset = Asset.new(params[:asset])

    respond_to do |format|
      if @asset.save
        flash[:notice] = 'Asset was successfully uploaded.'
        format.html { redirect_to assets_url }
        #format.xml  { head :created, :location => asset_url(@asset) }
      else
        format.html { render :action => "new" }
        #format.xml  { render :xml => @asset.errors.to_xml }
      end
    end
  end

  # PUT /assets/1
  # PUT /assets/1.xml
  # def update
  #   @asset = Asset.find(params[:id])
  # 
  #   respond_to do |format|
  #     if @asset.update_attributes(params[:asset])
  #       flash[:notice] = 'Asset was successfully updated.'
  #       format.html { redirect_to asset_url(@asset) }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render :action => "edit" }
  #       format.xml  { render :xml => @asset.errors.to_xml }
  #     end
  #   end
  # end

  # DELETE /assets/1
  # DELETE /assets/1.xml
  def destroy
    @asset = Asset.find(params[:id])
    @asset.destroy

    respond_to do |format|
      format.html { redirect_to assets_url }
      format.xml  { head :ok }
    end
  end    
    
end
