# === COPYRIGHT:
# Copyright (c) 2005-2011 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class BrontoController < ApplicationController
  before_filter :login_required
  before_filter :set_content_tag_and_community_and_topic
  layout 'pubsite'
  
  def index
    @right_column = false
    @filteredparameters = ParamsFilter.new([{:download => :string}],params)
    if(!@filteredparameters.download.nil? and @filteredparameters.download == 'csv')
      @sends = BrontoSend.where('sent >= ?',Date.today - 1.month).order('sent DESC')
      response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
      response.headers['Content-Disposition'] = 'attachment; filename=brontosends.csv'
      render(:template => 'bronto/csvlist', :layout => false)
    else
      @sends = BrontoSend.order('sent DESC').paginate(:page => params[:page])
    end
  end
  
  
end