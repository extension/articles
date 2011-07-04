#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'net/http'
require 'uri'
require 'date'


class Bronto < Thor
  include Thor::Actions
  
  # these are not the tasks that you seek
  no_tasks do
    # load rails based on environment
    
    def load_rails(environment)
      if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
        ENV["RAILS_ENV"] = environment
      end
      require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
    end
  end
  
  desc "get_deliveries_for_date", "Update Bronto Deliveries (also sends, messages, contacts) for specified date"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :date,:default => (Date.today-1).to_s, :aliases => "-d", :desc => "Date to get sends for"
  method_option :includeclicks,:default => true, :aliases => "-c", :desc => "Update clicks since the specified date"
  def get_deliveries_for_date
    load_rails(options[:environment])
    date = Date.parse(options[:date])
    bronto_connection = BrontoConnection.new
    deliveries = BrontoDelivery.get_sent_deliveries_for_date(date,bronto_connection)
    if(options[:includeclicks])
      clicks = BrontoSend.get_clicks_since(date,bronto_connection)
    end
  end
  
  desc "get_deliveries_since_date", "Update Bronto Deliveries (also sends, messages, contacts) since specified date"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :start_date,:default => (Date.today-1).to_s, :aliases => "-s", :desc => "Start date"
  method_option :end_date,:default => (Date.today-1).to_s, :aliases => "-e", :desc => "End Date"
  method_option :includeclicks,:default => true, :aliases => "-c", :desc => "Update clicks since the specified start date"
  def get_deliveries_since_date
    load_rails(options[:environment])
    date_start = Date.parse(options[:start_date])
    date_end = Date.parse(options[:end_date])
    bronto_connection = BrontoConnection.new
    date_start.upto(date_end) do |date|
      BrontoDelivery.get_sent_deliveries_for_date(date,bronto_connection)
    end
    if(options[:includeclicks])
      BrontoSend.get_clicks_since(date_start,bronto_connection)
    end
  end
end

Bronto.start
