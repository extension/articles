require 'zip_code_to_state'

class DataController < ApplicationController
  
  before_filter :get_community
  
  helper_method :get_month
  
  private
  
  def get_community
    @community = nil
    if @category && @category.name != 'all' && @category.community
      @community = @category.community
    end
    @personal[:community] = @community
    @topic = @community.topic if @community and @community.topic
  end
  
  def get_class
    nil
  end
  
  def get_month
    todays_date = Date.today
    
    if params[:year] && params[:month]
      begin
        @month = Date.civil(params[:year].to_i, params[:month].to_i, 1)
      rescue
        @month = Date.civil(todays_date.year, todays_date.month, 1)
      end
    else
      @month = Date.civil(todays_date.year, todays_date.month, 1)
    end
    @month
  end
  
  def no_right_column
    @right_column = false
  end
  
  def get_date
    if params[:year] && params[:month] && params[:date]
      @date = Date.civil(params[:year].to_i, params[:month].to_i, params[:date].to_i)
    elsif params[:year] && params[:month]
      @month = Date.civil(params[:year].to_i, params[:month].to_i, 1)
    else
      @date = Time.now.to_date
    end
    @date
  end
end