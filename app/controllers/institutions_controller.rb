class InstitutionsController < ApplicationController

  before_filter :set_page_title

  def index
    @institutions = Institution.find(:all, :order => 'state')
    @right_column = false
  end

  def show
    if params[:id].nil?
      redirect_to :action => 'index'
    else
      redirect_to :action => 'edit', :id => params[:id]
    end
  end

  def new
  end

  def edit
    @institution = Institution.find(params[:id])
    @right_column = false
  end

  def update
    @institution = Institution.find(params[:id])
  
    if @institution.update_attributes(params[:institution])
      flash[:notice] = 'Institution was successfully updated.'
      redirect_to :action => 'index', :id => @institution
    else
      flash[:error] = "Error updating link."
      render :action => "edit"
    end
  end 

protected
  
  def set_page_title
    set_title('Manage Institutions')
  end
end