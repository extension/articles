#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'net/http'
require 'uri'


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

  desc "panda_impact", "show panda impact on pages"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def panda_impact
    load_rails(options[:environment])
  end
    
end

Output.start
