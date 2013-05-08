# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ReportsController < ApplicationController
  layout 'pubsite'
  before_filter :signin_optional
  before_filter :signin_required, :only => [:bronto]

  def index
    set_title("Reports")
    set_titletag("Reports - eXtension")
    @right_column = false
  end

  def graphs
    data_url = "#{AppConfig.configtable['data_site']}"
    return redirect_to(data_url, :status => :moved_permanently)
  end

  def publishedcontent
    data_url = "#{AppConfig.configtable['data_site']}pages/publishedcontent"
    return redirect_to(data_url, :status => :moved_permanently)
  end

  def activitygraph
    data_url = "#{AppConfig.configtable['data_site']}"
    return redirect_to(data_url, :status => :moved_permanently)
  end

  def bronto
    @reporting = true
    @right_column = false
    @filteredparameters = ParamsFilter.new([{:start_date => {:datatype => :date, :default => (Date.yesterday - 1.month)}},
                                            {:end_date => {:datatype => :date, :default => (Date.yesterday)}},
                                            {:download => :string}],params)

    if(!@filteredparameters.download.nil? and @filteredparameters.download == 'csv')
      @sends = BrontoSend.where('sent >= ? and sent <=?',@filteredparameters.start_date,@filteredparameters.end_date).order('sent DESC')
      response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
      response.headers['Content-Disposition'] = 'attachment; filename=brontosends.csv'
      render(:template => 'reports/bronto_csvlist', :layout => false)
    else
      @sends = BrontoSend.where('sent >= ? and sent <=?',@filteredparameters.start_date,@filteredparameters.end_date).order('sent DESC').paginate(:page => params[:page])
    end
  end

end
