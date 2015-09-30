#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'lockfile'


class UnpublishContent < Thor
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





    def unpublish_page(page)
      node_id = page.create_node_id



    end

  end

  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def sources
    load_rails(options[:environment])
  end


# let us loop through the news, update the workflow,
# create some workflow events, and then destroy the page

# Page.where(datatype: 'News').limit(2).each do |page|
Page.where(datatype: 'News').find_each do |page|
  puts "\nProcessing Page ##{page.id}:"
  puts "... destroyed page."

end
