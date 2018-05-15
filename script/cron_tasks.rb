# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file
require 'rubygems'
require 'thor'

class CronTasks < Thor
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

    def check_unchecked
      # check the links not yet checked
      unchecked_count = Link.checklist.unchecked.count
      Link.checklist.unchecked.each do |link|
        link.queue_check_url
      end
      puts "Queued #{unchecked_count} unchecked urls for link checking" if unchecked_count > 0
    end

    def daily_link_check
      # queue up unchecked urls older than a day / 24 hours
      day_old_total_count = Link.checklist.checked_yesterday_or_earlier.count
      Link.checklist.checked_yesterday_or_earlier.order("last_check_at ASC").find_each do |link|
        link.queue_check_url
      end
      puts "Queued #{day_old_total_count} links for link checking" 
    end

    def daily_link_stat_updates
      Page.update_broken_flags
      LinkStat.update_counts
    end
  end

  desc "daily", "All daily cron tasks"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def daily
    load_rails(options[:environment])
    daily_link_check
    daily_link_stat_updates
  end

  desc "hourly", "All hourly cron tasks"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def hourly
    load_rails(options[:environment])
    check_unchecked
  end

end

CronTasks.start
