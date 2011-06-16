#!/usr/bin/env ruby
require 'rubygems'
require 'thor'

class Repoint < Thor
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
  
  desc "update_pages", "Update Darmok Pages to point to Drupal"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :drupal_database,:default => 'prod_create', :desc => "Database for drupal install"
  method_option :alias_pattern,:default => 'cop.extension.org', :desc => "Pattern for limiting aliases retrieved from the drupal database"
  method_option :drupal_host,:default => 'create.extension.org', :desc => "Host for drupal install"
  method_option :simulate,:default => false, :desc => "Simulate results (don't update darmok)"
  def update_pages
    load_rails(options[:environment])
    create_page_source = PageSource.find_by_name('create')
    darmok_config = Page.connection.instance_variable_get("@config")
    # build my select for the url_aliases
    url_alias_select_sql = "SELECT * from #{options[:drupal_database]}.url_alias where alias LIKE '%#{options[:alias_pattern]}%'"
    begin
      url_alias_rows = Page.connection.select_rows(url_alias_select_sql)
    rescue => err
      puts "ERROR: Exception raised during url alias retrieval: #{err}"
    end
    
    # build a select to find the pages we expected to see published
    expected_published_pages_sql = "SELECT node_id from #{options[:drupal_database]}.node_workflow where status_text = 'Published'"
    begin
      expected_nodes_rows = Page.connection.select_rows(expected_published_pages_sql)
    rescue => err
      puts "ERROR: Exception raised during url alias retrieval: #{err}"
    end
    
    expected_nodes = []
    expected_nodes_rows.each do |row|
      expected_nodes << row[0]
    end
    
    
    
    found_count = 0
    not_found_count = 0
    url_alias_rows.each do |row|
      found_match = false
      drupal_id = row[1]
      source = row[2]
      begin
        uri = URI.parse(source)
      rescue
        puts "Not a valid URI: #{source}"
      end
      
      if(uri and uri.path =~ %r{/wiki/(.*)})
        match_title = CGI.unescape($1)
        match_title.gsub!('_',' ')
        if(match_page = Page.find_by_title_and_page_source_id(match_title,1))
          current_source = match_page.source_url          
          new_source = "http://#{options[:drupal_host]}/node/#{drupal_id}"
          update_attributes = {:source => create_page_source.name, :page_source => create_page_source, :source_id => new_source, :source_url => new_source, :source_url_fingerprint => Digest::SHA1.hexdigest(new_source)}
          if(match_page.old_source_url.blank?)
            # in case this gets run twice, don't overwrite the old_source_url
            update_attributes.merge!({:old_source_url => current_source})
          end
          if(!options[:simulate])
            match_page.update_attributes(update_attributes)
          end
          found_match = true
        end
      end
      
      if(found_match)
        found_count += 1
        puts "Found Match:  #{match_page.id} : #{match_page.title} (Drupal ID: #{drupal_id})"
      elsif(expected_nodes.find_index(drupal_id))
        puts "Did not find Match:  #{drupal_id} : #{source}"
        not_found_count += 1
      end
    end
    puts "Found: #{found_count}"
    puts "Not Found: #{not_found_count}"
  end
  
  desc "update_faqs", "Update Darmok FAQs to point to Drupal"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :drupal_database,:default => 'prod_create', :desc => "Database for drupal install"
  method_option :drupal_host,:default => 'create.extension.org', :desc => "Host for drupal install"
  method_option :simulate,:default => false, :desc => "Simulate results (don't update darmok)"
  def update_faqs
    load_rails(options[:environment])
    create_page_source = PageSource.find_by_name('create')
    darmok_config = Page.connection.instance_variable_get("@config")
    # build my select for the url_aliases
    faq_mapping_select_sql = "SELECT node_id,CONCAT('http://cop.extension.org/questions/show/',faq_id) as faq_source_url,published_revision_id FROM #{options[:drupal_database]}.faq_drupal_mapping"
    begin
      faq_mapping_rows = Page.connection.select_rows(faq_mapping_select_sql)
    rescue => err
      puts "ERROR: Exception raised during url alias retrieval: #{err}"
    end
    
    found_count = 0
    not_found_count = 0
    faq_mapping_rows.each do |row|
      found_match = false
      drupal_id = row[0]
      faq_source_url = row[1]
      is_published = !(row[2].blank?)
    
      if(match_page = Page.find_by_source_url_and_page_source_id(faq_source_url,2))
        current_source = match_page.source_url          
        new_source = "http://#{options[:drupal_host]}/node/#{drupal_id}"
        update_attributes = {:source => create_page_source.name, :page_source => create_page_source, :source_id => new_source, :source_url => new_source, :source_url_fingerprint => Digest::SHA1.hexdigest(new_source)}
        if(match_page.old_source_url.blank?)
          # in case this gets run twice, don't overwrite the old_source_url
          update_attributes.merge!({:old_source_url => current_source})
        end
        if(!options[:simulate])
          match_page.update_attributes(update_attributes)
        end
        found_match = true
      end
      
      if(found_match)
        found_count += 1
        puts "Found Match:  #{match_page.id} : (Drupal ID: #{drupal_id})"
      elsif(is_published)
        puts "Did not find Match:  #{drupal_id} : #{faq_source_url}"
        not_found_count += 1
      end
    end
    puts "Found: #{found_count}"
    puts "Not Found: #{not_found_count}"
  end  
  
  
  
  
  
end

Repoint.start