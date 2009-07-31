#!/usr/bin/env ruby
require 'getoptlong'
### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--refreshall","-r", GetoptLong::NO_ARGUMENT ],
  [ "--datadate","-d", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@refreshall = false
@provided_date = nil
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--refreshall'
      @refreshall = true
    when '--datadate'
      @provided_date = arg
    else
      puts "Unrecognized option #{opt}"
      exit 0
    end
end
### END Program Options

if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
  ENV["RAILS_ENV"] = @environment
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

def update_all_published_numbers(datadate)
  DailyNumber.all_item_count_for_date(Event,datadate,'published events','total',true)
  DailyNumber.all_item_count_for_date(Faq,datadate,'published faqs','total',true)
  DailyNumber.all_item_count_for_date(Article,datadate,'published articles','total',true)
  DailyNumber.all_item_count_for_date(Article,datadate,'published news','total',true)
  DailyNumber.all_item_count_for_date(Article,datadate,'published learning lessons','total',true)
  DailyNumber.all_item_count_for_date(Article,datadate,'published features','total',true)
end

def update_community_published_numbers(community,datadate)
  community.item_count_for_date(datadate,'published events','total',true)
  community.item_count_for_date(datadate,'published faqs','total',true)
  community.item_count_for_date(datadate,'published articles','total',true)
  community.item_count_for_date(datadate,'published news','total',true)
  community.item_count_for_date(datadate,'published learning lessons','total',true)
  community.item_count_for_date(datadate,'published features','total',true)
end

if(!@provided_date.nil?)
  @datadate = Date.parse(@provided_date)
else
  @datadate = Date.yesterday
end
  
@communities_list = Community.launched
if(@refreshall)
  datadate = AppConfig.configtable['content_feed_refresh_since'].to_date
  while(datadate <= Date.yesterday) do
    update_all_published_numbers(datadate)
    @communities_list.each do |c|
      update_community_published_numbers(c,datadate)
    end
    datadate += 1.day
  end
else
  update_all_published_numbers(@datadate)
  @communities_list.each do |c|
    update_community_published_numbers(c,@datadate)
  end
end
  
