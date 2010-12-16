#!/usr/bin/env ruby
require 'rubygems'
require 'trollop'
require 'thread'


default_date = (Date.today - 1).to_s #Date.yesterday is rails, and rails isn't loaded yet

commandline_options = Trollop::options do
  opt(:refreshall,"Refresh all data", :short => 'a', :default => false)
  opt(:datadate,"Date to process numbers for", :short => 'd', :default => default_date)
  opt(:datatype,"Datatype (all, events, faqs, articles, news, learning lessions or features)", :short => 't', :default => 'all')
  opt(:environment,"Rails environment to start", :short => 'e', :default => 'production')
end

if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
  ENV["RAILS_ENV"] = commandline_options[:environment]
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

KNOWN_DATATYPES = ['events','faqs','articles','news','learning lessons','features']

def update_all_published_numbers(datadate,datatype = 'all')
  if(datatype.nil? or datatype == 'all')
    KNOWN_DATATYPES.each do |known_datatype|
      DailyNumber.all_item_count_for_date(Article,datadate,"published #{known_datatype}",'total',true)
    end
  else
    DailyNumber.all_item_count_for_date(Article,datadate,"published #{datatype}",'total',true)
  end
end

def update_community_published_numbers(community,datadate,datatype = 'all')
  if(datatype.nil? or datatype == 'all')
    KNOWN_DATATYPES.each do |known_datatype|
      community.item_count_for_date(datadate,"published #{known_datatype}",'total',true)
    end      
  else
    community.item_count_for_date(datadate,"published #{datatype}",'total',true)
  end
end

if(commandline_options[:datadate])
  @datadate = Date.parse(commandline_options[:datadate])
else
  @datadate = Date.yesterday
end

if(!((KNOWN_DATATYPES + ['all']).include?(commandline_options[:datatype])))
  @datatype = 'all'
else
  @datatype = commandline_options[:datatype]
end
  
@communities_list = Community.launched
if(commandline_options[:refreshall])
  datadate = AppConfig.configtable['content_feed_refresh_since'].to_date
  while(datadate <= Date.yesterday) do
    update_all_published_numbers(datadate,@datatype)
    @communities_list.each do |c|
      update_community_published_numbers(c,datadate,@datatype)
    end
    datadate += 1.day
  end
else
  update_all_published_numbers(@datadate,@datatype)
  @communities_list.each do |c|
    update_community_published_numbers(c,@datadate,@datatype)
  end
end
  
