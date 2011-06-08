#!/usr/bin/env ruby
# flash_reference_rewrite uses mysql2 and nokogiri to process 
# rendered mediawiki articles for references to flash files, and
# inject a stylized paragraph so that content authors can manage
# their content.
require 'rubygems'
require 'thor'
require 'mysql2'
require 'nokogiri'
require 'yaml'
require 'fastercsv'
require 'uri'

class Rewrite < Thor

  # these are not the tasks that you seek
  no_tasks do
    def mysql_connect(environment,drupaldb)
      # Load database username and password informattion from a database.yaml file located in config/
      configfile = File.expand_path(File.dirname(__FILE__) + "/../config/database.yml")
      if File.exists?(configfile) then
        dbsettings = YAML.load_file(configfile)
        if(dbsettings[environment])
          @username = dbsettings[environment]['username']
          @password = dbsettings[environment]['password']
          @host = dbsettings[environment]['host']
          @port = dbsettings[environment]['port']
          connect_settings = {:host => @host, :username => @username, :port => @port, :password => @password, :database => drupaldb}
          dbconnection = Mysql2::Client.new(connect_settings)
        end
      end
      dbconnection
    end
  end
  
  desc "rewrite_flash_references", "Output node id, node title, node groups,"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Database environment"
  method_option :drupaldb,:default => 'prod_create', :aliases => "-d", :desc => "Drupal database"
  method_option :simulate,:default => false, :aliases => "-s", :desc => "Simulate update, don't actually run the update query"
  method_option :outputurls,:default => false, :aliases => "-u", :desc => "Put found urls into the output csv file"
  def rewrite_flash_references
    dbconnection = mysql_connect(options[:environment],options[:drupaldb])
    if(dbconnection.nil?)
      $stderr.puts "Error! unable to make database connection"
      exit(1)
    end
    
    # query drupal db for flash references
    # and loop through results.  Some articles might mention
    # "SWFObject" as documentation - but the regex's will filter
    # those out.
    results = dbconnection.query("SELECT * FROM field_data_body WHERE body_value LIKE '%SWFObject%'")
    node_urls = {}
    if(results.nil?)
      $stderr.puts "No results for SWFObject query!"
      exit(1)
    end
    
    results.each do |entry|
      parsed_html = Nokogiri::HTML::DocumentFragment.parse(entry['body_value'])
      found_urls = []
      remove_refs = []
      # look for <script> tags
      parsed_html.css('script').each do |scriptreference|
        cdata_block = scriptreference.children[0]
        # is there an SWFObject("url") reference in the
        # first child block?  Then get that URL
        if(cdata_block.text =~ %r{SWFObject\("(http://.+?)"})
          url = $1
          # the url might be a reference to our own mediaplayer, if so,
          # we need to get the "file" param out of the cdata block
          if(url =~ %r{Mediaplayer\.swf})
            # look for file variable
            if(cdata_block.text =~ %r{so\.addVariable\("file", "(http://.+?)"})
              url = $1
            end
          end
          
          # change cop file references to create
          begin
            uri = URI.parse(url)
            if uri.host == 'cop.extension.org'
              uri.host = 'create.extension.org'
            end
            if uri.path =~ %r{/mediawiki/files/(.*)}
              uri.path = '/sites/default/files/w/' + $1
            end
            foundurl = uri.to_s            
          rescue
            foundurl = url
          end
          found_urls << foundurl
          remove_refs << scriptreference
        end
      end
      remove_refs.each do |ref|
        ref.remove
      end

      # find the flashcontainer divs so that we'll restyle them
      # and replace the text.  the # of flashcontainers should match the number of
      # found URLs - it's at least that way for the tested content
      if(!options[:simulate])      
        flashboxes = parsed_html.css('div.flashcontainer')
        flashboxes.each_with_index do |flashbox,index|
          flashbox.children.remove
          if(found_urls[index])
            new_content = Nokogiri::HTML::DocumentFragment.parse("<strong>WARNING: Video reference update needed!</strong>. This article used a mediawiki-specific feature to reference the following video file:  <a href='#{found_urls[index]}'>#{found_urls[index]}</a>. Please visit <a href='http://create.extension.org/node/4992'>http://create.extension.org/node/4992</a> to learn more about how to reference the video file within create.extension.org.")
            flashbox.children = new_content
            flashbox.set_attribute('style',"background: #f47B28;border:1px solid #000;color:#fff;")
          end
        end
        update_value = dbconnection.escape(parsed_html.to_html)
        update = dbconnection.query("UPDATE field_data_body SET body_value = '#{update_value}' WHERE entity_id = #{entry['entity_id']}")
      end
      
      if(found_urls.size >= 1)
        node_urls[entry['entity_id']] = {}
        node_urls[entry['entity_id']]['urls'] = found_urls
      
        # query for the node title
        results = dbconnection.query("Select title from node WHERE node.nid = #{entry['entity_id']}")
        if(results.first and results.first['title'])
          node_urls[entry['entity_id']]['title'] = results.first['title']
        end
      
        # query for the node groups
        node_urls[entry['entity_id']]['groups'] = []
        results = dbconnection.query("Select node.title from node,field_data_group_audience WHERE node.nid = field_data_group_audience.group_audience_gid and field_data_group_audience.entity_id = #{entry['entity_id']} and field_data_group_audience.entity_type = 'node'")
        results.each do |result|
          node_urls[entry['entity_id']]['groups'] << result['title']
        end
      end
    end
    
    timestring = Time.now.strftime('%Y%m%d%H%M%S')
    FasterCSV.open(File.expand_path("~/video_references_#{timestring}.csv"), "w") do |csv|
      csv << ['Group','Node','Node Title','Video References']
      node_urls.each do |node_id,data|
        if(data['groups'].empty?)
          datarow = ['None',node_id,data['title'],data['urls'].size]
          if(options[:outputurls])
            data['urls'].each do |url|
              datarow << url
            end
          end
          csv << datarow
        else 
          data['groups'].each do |group| 
            datarow = [group,node_id,data['title'],data['urls'].size]
            if(options[:outputurls])
              data['urls'].each do |url|
                datarow << url
              end
            end
            csv << datarow
          end
        end
      end
    end
  end
end

Rewrite.start

  
  