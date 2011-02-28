#!/usr/bin/env ruby
# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'getoptlong'
require 'uri'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'

progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
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

# get the pages
@pages = Page.indexed
index_pages_count = (@pages.size / 10000) + 1


def split_array(array, chunks)
  size = array.size
  splitpoint = (size/chunks)
  splits = []
  start = 0
  1.upto(chunks) do |i|
    last = start+splitpoint
    last = last-1 unless size%chunks >= i
    splits << array[start..last] || []
    start = last+1
  end
  splits
end

# create the index
File.open("#{RAILS_ROOT}/public/sitemaps/sitemap_index.xml", 'w') do |sitemap_index|
  sitemap_index.puts('<?xml version="1.0" encoding="UTF-8"?>')
  sitemap_index.puts('<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
  # communities
  sitemap_index.puts('<sitemap>')
  sitemap_index.puts('<loc>http://www.extension.org/sitemap_communities.xml</loc>')
  sitemap_index.puts('</sitemap>')
  # pages
  if(index_pages_count == 1)
    sitemap_index.puts('<sitemap>')
    sitemap_index.puts('<loc>http://www.extension.org/sitemap_pages.xml</loc>')
    sitemap_index.puts('</sitemap>')
  else
    for i in (1..index_pages_count)
      sitemap_index.puts('<sitemap>')
      sitemap_index.puts("<loc>http://www.extension.org/sitemap_pages_#{i}.xml</loc>")
      sitemap_index.puts('</sitemap>')
    end
  end
  sitemap_index.puts('</sitemapindex>')
end

# communities
File.open("#{RAILS_ROOT}/public/sitemaps/sitemap_communities.xml", 'w') do |sitemap_communities|
  sitemap_communities.puts('<?xml version="1.0" encoding="UTF-8"?>')
  sitemap_communities.puts('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
  Community.launched.each do |community|
    community.cached_content_tags.each do |name|
      sitemap_communities.puts('<url>')
      sitemap_communities.puts("<loc>http://www.extension.org/#{URI.encode(name)}</loc>")
      sitemap_communities.puts('</url>')
    end
  end
  sitemap_communities.puts('</urlset>')
end

# pages
if(index_pages_count == 1)
  File.open("#{RAILS_ROOT}/public/sitemaps/sitemap_pages.xml", 'w') do |sitemap_pages|
    sitemap_pages.puts('<?xml version="1.0" encoding="UTF-8"?>')
    sitemap_pages.puts('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    @pages.each do |page|
      sitemap_pages.puts('<url>')
      sitemap_pages.puts("<loc>http://www.extension.org/pages/#{page.id}/#{page.url_title}</loc>")
      sitemap_pages.puts("<lastmod>#{page.source_updated_at.xmlschema}</loc>")      
      sitemap_pages.puts('</url>')
    end
    sitemap_pages.puts('</urlset>')
  end
else
  splits = split_array(@pages,index_pages_count)
  for i in (1..index_pages_count)
    File.open("#{RAILS_ROOT}/public/sitemaps/sitemap_pages_#{i}.xml", 'w') do |sitemap_pages|
      sitemap_pages.puts('<?xml version="1.0" encoding="UTF-8"?>')
      sitemap_pages.puts('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
      splits[i-1].each do |page|
        sitemap_pages.puts('<url>')
        sitemap_pages.puts("<loc>http://www.extension.org/pages/#{page.id}/#{page.url_title}</loc>")
        sitemap_pages.puts("<lastmod>#{page.source_updated_at.xmlschema}</loc>")      
        sitemap_pages.puts('</url>')
      end
      sitemap_pages.puts('</urlset>')
    end
  end
end