# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ReportsController < ApplicationController
  layout 'pubsite'
  before_filter :login_optional
  before_filter :login_required, :only => [:bronto]
  
  def index    
    set_title("Reports")
    set_titletag("Reports - eXtension")
    @right_column = false
  end
  
  
  def graphs
    @right_column = false
  end
  
  def publishedcontent
    data_url = "#{AppConfig.configtable['data_site']}pages/publishedcontent"
    return redirect_to(data_url, :status => :moved_permanently)
  end
  
  def activitygraph
    @right_column = false
    datatype = params[:datatype].nil? ? 'hourly' : params[:datatype]
    if(params[:primary_type].nil?)
      @graphtype = params[:graphtype] || ((datatype == 'weekday' or datatype == 'hourly') ? 'column' : 'area')
    else # assume comparison
      @graphtype = params[:graphtype] || 'area'
    end
    
    urloptions = params
    urloptions.merge!({:action => :activitytable,:controller => 'api/gviz', :datatype => datatype, :graphtype => @graphtype}) 
    
    @page_title = "#{datatype.capitalize} Activity"
    
    if(params[:dateinterval])
      @page_title += " (dates: #{@dateinterval})"
    end
    
    @chart_options = {:querysource => url_for(urloptions)}
       
    if (@graphtype == 'column')
      @chart_partial = 'reports/columnchart'
      @chart_options.merge!({:width => 800,:height => 480,:chartdiv => 'visualization_chart',:legend => 'bottom',:lineSize => 2, :pointSize => 3})
    elsif(@graphtype == 'timeline')
      @chart_partial = 'reports/timeline'
      @chart_options.merge!({:width => 800,:height => 480,:chartdiv => 'visualization_chart',:legend => 'bottom',:lineSize => 2, :pointSize => 3})
    else   
      @chart_partial = 'reports/areachart'
      @chart_options.merge!({:width => 800,:height => 480,:chartdiv => 'visualization_chart',:legend => 'bottom',:lineSize => 2, :pointSize => 3})
    end
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
