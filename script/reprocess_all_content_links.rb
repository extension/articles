#!/usr/bin/env ruby
require 'rubygems'
require 'trollop'
require 'net/http'
require 'uri'

commandline_options = Trollop::options do
  opt(:environment,"Rails environment to start", :short => 'e', :default => 'production')
end

if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
  ENV["RAILS_ENV"] = commandline_options[:environment]
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

# dump all content links and linkings
Link.connection.execute('truncate table links;')
Linking.connection.execute('truncate table linkings;')

# primary content links - these are the links for each articles
processed_count = 1
puts "Creating content links for each article"
Page.all.each do |page|
  puts "Processing Page: #{page.id} ##{processed_count}"
  page.create_primary_link
  processed_count += 1
end

# processed_count = 1
# puts "Processing in-article links"
# Page.all.each do |article|
#   puts "Processing Article: #{article.id} ##{processed_count}"
#   links = article.convert_links
#   article.save
#   puts "Links: #{links.inspect}"
#   processed_count += 1
# end
