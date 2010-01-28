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

processed_count = 1
Article.all.each do |article|
  puts "Processing Article: #{article.id} ##{processed_count}"
  links = article.convert_links
  article.save
  puts "Images: #{images} Links: #{links.inspect}"
  processed_count += 1
end
