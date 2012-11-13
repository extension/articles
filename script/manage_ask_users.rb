# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file
require 'rubygems'
require 'thor'
require 'benchmark'

class AskImporter < Thor
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

    def get_people_database
      ActiveRecord::Base.connection.instance_variable_get("@config")[:database]
    end

    def people_account_update_query(ask_database = 'prod_aae')
      people_database = get_people_database
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      UPDATE #{ask_database}.users, #{people_database}.accounts
      SET #{ask_database}.users.login = #{people_database}.accounts.login, 
          #{ask_database}.users.first_name=#{people_database}.accounts.first_name,
          #{ask_database}.users.last_name=#{people_database}.accounts.last_name,
          #{ask_database}.users.retired=#{people_database}.accounts.retired,
          #{ask_database}.users.is_admin=#{people_database}.accounts.is_admin,
          #{ask_database}.users.email=#{people_database}.accounts.email,
          #{ask_database}.users.time_zone = #{people_database}.accounts.time_zone
      WHERE #{ask_database}.users.darmok_id = #{people_database}.accounts.id 
      AND #{ask_database}.users.kind = 'User'
      AND #{people_database}.accounts.vouched=1
      END_SQL
      query
    end


    def people_account_conversion_query(ask_database = 'prod_aae')
      people_database = get_people_database
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      UPDATE #{ask_database}.users, #{people_database}.accounts
      SET #{ask_database}.users.kind = 'User',
          #{ask_database}.users.darmok_id = #{people_database}.accounts.id,
          #{ask_database}.users.login = #{people_database}.accounts.login,
          #{ask_database}.users.first_name=#{people_database}.accounts.first_name, 
          #{ask_database}.users.last_name=#{people_database}.accounts.last_name,
          #{ask_database}.users.retired=#{people_database}.accounts.retired,
          #{ask_database}.users.is_admin=#{people_database}.accounts.is_admin,
          #{ask_database}.users.email=#{people_database}.accounts.email,
          #{ask_database}.users.time_zone = #{people_database}.accounts.time_zone
      WHERE #{ask_database}.users.email = #{people_database}.accounts.email
      AND #{ask_database}.users.kind = 'PublicUser' 
      AND #{people_database}.accounts.vouched=1
      END_SQL
      query
    end

    def people_account_insert_query(ask_database = 'prod_aae')
      people_database = get_people_database
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{ask_database}.users (first_name,last_name,kind,email, time_zone,darmok_id,is_admin,created_at, updated_at) 
      SELECT #{people_database}.accounts.first_name,
             #{people_database}.accounts.last_name, 
             'User',
             #{people_database}.accounts.email, 
             #{people_database}.accounts.time_zone, 
             #{people_database}.accounts.id, 
             #{people_database}.accounts.is_admin, 
             #{people_database}.accounts.created_at, 
             NOW()
      FROM #{people_database}.accounts LEFT JOIN #{ask_database}.users ON #{people_database}.accounts.id = #{ask_database}.users.darmok_id
      WHERE #{ask_database}.users.darmok_id IS NULL AND #{people_database}.accounts.retired = 0 and #{people_database}.accounts.vouched = 1
      END_SQL
      query
    end


    def people_authmap_insert_query(ask_database = 'prod_aae')
      people_database = get_people_database
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT IGNORE INTO #{ask_database}.authmaps (user_id, authname, source, created_at, updated_at) 
      SELECT #{ask_database}.users.id, 
             CONCAT('https://people.extension.org/',#{people_database}.accounts.login), 
             'people', 
             #{people_database}.accounts.created_at, NOW()
      FROM #{ask_database}.users,#{people_database}.accounts
      WHERE #{ask_database}.users.darmok_id = #{people_database}.accounts.id
      END_SQL
      query
    end

    def update_accounts(ask_database = 'prod_aae')
      puts "Starting account update..." if options[:verbose]
      benchmark = Benchmark.measure do
        Account.connection.execute(people_account_update_query(ask_database))
      end
      puts "\t Finished account update: #{benchmark.real.round(2)}s" if options[:verbose]      
    end

    def convert_accounts(ask_database = 'prod_aae')
      puts "Starting account conversion..." if options[:verbose]
      benchmark = Benchmark.measure do
        Account.connection.execute(people_account_conversion_query(ask_database))
      end
      puts "\t Finished account conversion: #{benchmark.real.round(2)}s" if options[:verbose]      
    end

    def insert_new_accounts(ask_database = 'prod_aae')
      puts "Starting new account import..." if options[:verbose]
      benchmark = Benchmark.measure do
       Account.connection.execute(people_account_insert_query(ask_database))
      end
      puts "\t Finished new account import: #{benchmark.real.round(2)}s" if options[:verbose]     
    end

    def insert_authmaps(ask_database = 'prod_aae')
      puts "Starting authmap insertion..." if options[:verbose]
      benchmark = Benchmark.measure do
        Account.connection.execute(people_authmap_insert_query(ask_database))
      end
      puts "\t Finished authmap insertion: #{benchmark.real.round(2)}s" if options[:verbose]     
    end

  end


  desc "all_the_accounts", "Update, convert, import, and set authmaps for people accounts"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :ask_database, :aliases => "-d", :default => 'prod_aae', :desc => "Ask Database"
  def all_the_accounts
    load_rails(options[:environment])
    update_accounts(options[:ask_database])
    convert_accounts(options[:ask_database])
    insert_new_accounts(options[:ask_database])
    insert_authmaps(options[:ask_database])
  end

end

AskImporter.start