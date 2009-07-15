# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module MainHelper
  
  def get_calendar_month
    todays_date = Date.today
    if params[:year] && params[:month]
      begin
        month = Date.civil(params[:year].to_i, params[:month].to_i, 1)
      rescue
        month = Date.civil(todays_date.year, todays_date.month, 1)
      end
    else
      month = Date.civil(todays_date.year, todays_date.month, 1)
    end
    
    return month
  end
  
  def get_calendar_date
    if params[:year] && params[:month] && params[:date]
      date = Date.civil(params[:year].to_i, params[:month].to_i, params[:date].to_i)
    elsif params[:year] && params[:month]
      date = Date.civil(params[:year].to_i, params[:month].to_i, 1)
    else
      date = Time.now.to_date
    end
    
    return date
  end
  
end
