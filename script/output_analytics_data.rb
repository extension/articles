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

  desc "panda_entrance_impact", "show panda impact on pages"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :file, :aliases => "-f", :required => true, :desc => "Import File, must be valid CSV (please replace all double quotes \"\" with %22 before importing)"
  method_option :combinedtags,:default => true, :desc => "Output content tags on one line"
  def panda_entrance_impact
    load_rails(options[:environment])
    FasterCSV.open(options[:file], "w") do |csv|
      csv << ["Page", "DataType", "URL Title", "Source URL", "Source Created", "Source Updated", "PrePanda", "PostPanda", "Panda Difference", "Panda Percentage", "PrePanda 24 Weeks", "PrePanda 3Week Avg","Last 27 Weeks","Size","Words","Total Links","External Links","Local Links","Internal Links","Tags"]
      Page.includes(:cached_tags).all.each do |page|
        csvoutput = []
        csvoutput << page.id
        csvoutput << page.datatype
        csvoutput << page.url_title
        csvoutput << page.source_url
        csvoutput << page.source_created_at.to_s
        csvoutput << page.source_updated_at.to_s
        csvoutput << page.analytics_entrances('prePanda')
        csvoutput << page.analytics_entrances('postPanda')
        (difference,percentage) = page.diff_analytics_entrances('postPanda','prePanda')
        csvoutput << difference
        csvoutput << percentage
        
        prepanda_24 = page.analytics.where("end_date < '2011/02/24'").sum(:entrances)        
        csvoutput << prepanda_24
        csvoutput << prepanda_24 / 8.to_f
        
        csvoutput <<  page.analytics.sum(:entrances)       
        csvoutput << page.content_length
        csvoutput << page.content_words
        links = page.link_counts
        csvoutput << links[:total]
        csvoutput << links[:external]
        csvoutput << links[:local]
        csvoutput << links[:internal]
        if(options[:combinedtags])
          csvoutput << page.community_content_tag_names.join(',')
          csv << csvoutput
        else
          page.community_content_tag_names.each do |tagname|
            output = csvoutput + [tagname]
            csv << output
          end
        end
      end
    end
  end
  
  desc "import_analytics_entrance_data", "Imports an edited CSV from GA including entrances,bounces,bouncerate"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :start_date,:default => '', :desc => "Start Date for data"
  method_option :end_date,:default => '', :desc => "End Date for data"
  method_option :file, :aliases => "-f", :required => true, :desc => "Import File, must be valid CSV (please replace all double quotes \"\" with %22 before importing)"
  method_option :datalabel, :required => true, :aliases => "-l", :desc => "Label for these analytics entries"
  def import_analytics_entrance_data
    load_rails(options[:environment])
    data_attributes = {}
    if(options[:start_date])
      data_attributes[:start_date] = Date.parse(options[:start_date])
    end
    
    if(options[:end_date])
      data_attributes[:end_date] = Date.parse(options[:end_date])
    end
      
    if File.exists?(options[:file])
      processed_count = 0    
      FasterCSV.foreach(options[:file]) do |row|
        next if(row.blank?) # skip blank rows
        (analytics_url,entrances,bounces,bouncerate) = row
        next if(analytics_url == 'Page') # skip title row
        processed_count +=1 
        outputstring = ("Processed Record ##{processed_count} : #{analytics_url}")
        if(analytic = Analytic.find_by_recordsignature(options[:datalabel],analytics_url))
          data_attributes.merge!({:entrances => entrances,:bounces => bounces, :bouncerate => bouncerate})
          analytic.update_attributes(data_attributes)
          puts("#{outputstring} : (Updated)") if(options[:verbose])
        else
          data_attributes.merge!({:datalabel => options[:datalabel], :analytics_url => analytics_url, :entrances => entrances,:bounces => bounces, :bouncerate => bouncerate})
          analytic = Analytic.create(data_attributes)
          puts("#{outputstring} : (New)") if(options[:verbose])
        end
      end
    else
      $stderr.puts "File does not exist! #{options[:file]}"
    end
  end   
end

Output.start
