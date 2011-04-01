#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'faster_csv'

class Output < Thor
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

  desc "output_pages_for_huckleberry", "Output a list of pages for huckleberry"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :file, :aliases => "-f", :required => true, :desc => "Output File"
  def output_pages_for_huckleberry
    load_rails(options[:environment])
    FasterCSV.open(options[:file], "w") do |csv|
      csv << ["ID", "Migrated ID", "DataType", "Title", "URL Title", "Content Length", "Content Words", "Source Created", "Source Updated", "Source", "Source URL", "Index","DPL", "Created At", "Updated At","Total Links","External Links","Local Links","Internal Links","Tags"]
      page_count = 0
      page_list = Page.includes(:cached_tags).all
      total_page_count = page_list.size
      page_list.each do |page|
        page_count += 1
        puts "Processing Page ##{page_count} of #{total_page_count} (ID: #{page.id})" if options[:verbose]
        csvoutput = []
        csvoutput << page.id
        csvoutput << page.migrated_id
        csvoutput << page.datatype
        csvoutput << page.title        
        csvoutput << page.url_title
        csvoutput << page.content_length
        csvoutput << page.content_words
        csvoutput << page.source_created_at.to_s
        csvoutput << page.source_updated_at.to_s
        csvoutput << page.source
        csvoutput << page.source_url
        csvoutput << (page.indexed? ? 1 : 0)
        csvoutput << (page.is_dpl? ? 1 : 0)
        csvoutput << page.created_at
        csvoutput << page.updated_at    
        links = page.link_counts
        csvoutput << links[:total]
        csvoutput << links[:external]
        csvoutput << links[:local]
        csvoutput << links[:internal]
        csvoutput << page.community_content_tag_names.join(',')
        csv << csvoutput
      end
    end
  end

end

Output.start
