#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'lockfile'


class Unpublish < Thor
  include Thor::Actions

  # constants


  # these are not the tasks that you seek
  no_tasks do
    # load rails based on environment

    def load_rails(environment)
      if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
        ENV["RAILS_ENV"] = environment
      end
      require_relative("../config/environment")
    end

    def recreate_primary_links(verbose = false)
      # dump the links table
      Link.connection.execute('truncate table links;')
      page_count = 1
      puts "Creating content links for each page"
      Page.all.each do |page|
        if(verbose)
          puts "    Processing Page: #{page.id} ##{page_count}"
        end
        page.create_primary_link
        page_count += 1
      end
      return page_count
    end

    def recreate_linkings(verbose = false)
      # dump the linkings table
      Linking.connection.execute('truncate table linkings;')
      page_count = 1
      returndata = {}
      puts "Processing in-page links"
      errors = {}
      Page.all.each do |page|
        if(verbose)
          puts "    Processing Page: #{page.id} (#{page.datatype}) ##{page_count}"
        end
        begin
          links = page.convert_links
          page.set_sizes
          page.save
          if(verbose)
            puts "Links: #{links.inspect}"
          end
          links.keys.each do |key|
            if(returndata[key])
              returndata[key] += links[key]
            else
              returndata[key] = links[key]
            end
          end
          page_count += 1
        rescue StandardError => error
          puts "Error! #{error}"
          errors[page.id] = error
        end
      end
      returndata[:page_count] = page_count
      returndata[:errors] = errors
      returndata
    end

  end

  desc "update_keep_flag", "updates keep flag from imageaudit"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def update_keep_flag
    load_rails(options[:environment])
    puts "Updating keep flags from the imageaudit database"
    Page.update_keep_from_imageaudit
    puts "Pages to keep #{Page.keep.count}"
    puts "Pages to unpublish #{Page.unpublish.count}"
  end

  desc "all_the_things", "Unpublish all pages marked to unpublish"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Output verbose progress"
  def all_the_things
    load_rails(options[:environment])
    puts "Updating keep flags from the imageaudit database" if (options[:verbose])
    Page.update_keep_from_imageaudit
    unpublish_count = Page.unpublish.count
    puts "Pages to unpublish #{unpublish_count} ... starting unpublish process" if (options[:verbose])
    Page.unpublish.find_each do |page|
      print "    Processing Page ##{page.id}... " if (options[:verbose])
      page.unpublish
      result = page.delete
      puts " #{result ? 'Deleted' : 'Not Deleted'}"
    end

    # handle rebuilding all the links
    recreate_primary_links(options[:verbose])
    returndata = recreate_linkings(options[:verbose])
    if(!returndata[:errors].blank?)
      puts "Errors:"
      returndata[:errors].each do |page_id,error|
        puts "Page ID: #{page_id}"
        puts "Error: #{error}"
      end
    end

    # clean up bucketings
    puts "Cleaning up bucketings" if (options[:verbose])
    Bucketing.cleanup
    puts "\nUnpublished #{unpublish_count} pages." if (options[:verbose])

  end

end

Unpublish.start
