#!/usr/bin/env ruby
require 'rubygems'

# load rails
if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
  ENV["RAILS_ENV"] = 'production'
end
require_relative("../../config/environment")

class CreateNodeWorkflow < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name='node_workflow'
  self.primary_key="nwid"
end


class CreateNodeWorkflowEvent < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name='node_workflow_events'
  self.primary_key="weid"
end

class CreateNode < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name='node'
  self.primary_key="nid"
  self.inheritance_column = "none"
  bad_attribute_names :changed
end

class CreateFieldDataBody < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name='field_data_body'
end

# let's delete some buckets
ContentBucket.where("name IN ('news','originalnews','notnews')").each do |bucket|
  puts "Cleaning up the #{bucket.name} content bucket"
  # delete the bucketings faster
  Bucketing.delete_all("content_bucket_id = #{bucket.id}")
  bucket.destroy
end

puts " --- "

# let us loop through the news, update the workflow,
# create some workflow events, and then destroy the page

# Page.where(datatype: 'News').limit(2).each do |page|
Page.where(datatype: 'News').find_each do |page|
  puts "\nProcessing Page ##{page.id}:"
  node_id = page.create_node_id

  if(create_node = CreateNode.where(nid: node_id).first)
    puts "... found node ##{create_node.nid} (#{create_node.type})."
    if(cnw = CreateNodeWorkflow.where(node_id: node_id).last)
      unix_timestamp = Time.now.utc.to_i
      cnw.update_attributes(active: false,
                            status_text: 'Draft',
                            status: 1,
                            review_count: 0,
                            draft_status: nil,
                            draft_status_text: nil,
                            published_at: nil,
                            unpublished_at: unix_timestamp,
                            published_revision_id: nil,
                            changed: unix_timestamp)
      puts "... updated node workflow (id #{cnw.nwid})."

      # need some workflow events
      CreateNodeWorkflowEvent.create(node_id: node_id,
                                     node_workflow_id: cnw.nwid,
                                     user_id: 1,
                                     revision_id: cnw.current_revision_id,
                                     event_id: 6,
                                     description: 'unpublished',
                                     created: unix_timestamp)

      CreateNodeWorkflowEvent.create(node_id: node_id,
                                     node_workflow_id: cnw.nwid,
                                     user_id: 1,
                                     revision_id: cnw.current_revision_id,
                                     event_id: 7,
                                     description: 'made inactive',
                                     created: unix_timestamp)

      puts "... logged workflow events."


      # inject some markup that lets viewers know what happened
      if(body = CreateFieldDataBody.where(bundle: create_node.type).where(entity_id: create_node.id).first)
        if(create_node.type == 'article')
          body_block = <<-END_TEXT.gsub(/\s+/, " ").strip
          <div id="news_removal_notes" style="background: #ffff00;border:1px solid #000;color:#000;">
          <p>On December 3, 2014, eXtension unpublished and removed all News content from www.extension.org.
          This Article, because it was tagged "news" has been unpublished and marked as inactive.
          Please feel free to rework this page and republish it as an indexed Article as appropriate.
          Do not hesitate to <a href="http://create.extension.org/node/99714">Contact
          our Community Support staff</a> with any questions you may have.</p></div>
          <br/>
          END_TEXT
        else
          body_block = <<-END_TEXT.gsub(/\s+/, " ").strip
          <div id="news_removal_notes" style="background: #ffff00;border:1px solid #000;color:#000;">
          <p>On December 3, 2014, eXtension unpublished and removed all News content from www.extension.org.
          This News page has been unpublished and marked as inactive. If you would like to rework this page
          into an Article and republish it, please <a href="http://create.extension.org/node/99714">Contact
          our Community Support staff</a> to convert this page or get more clarification.</p></div>
          <br/>
          END_TEXT
        end

        body.connection.execute("UPDATE #{CreateFieldDataBody.table_name} SET body_value = #{ActiveRecord::Base.quote_value(body_block + body.body_value)} where bundle = '#{create_node.type}' AND entity_id = #{create_node.id}")
        puts "... updated body content with disclaimer for node ##{create_node.id}."
      else
        puts "... unable to find body content for node ##{create_node.id}."
      end
    else
      puts "... unable to find a workflow entry for this node (create node id: #{node_id})."
    end
  else
    puts "... did not find a Create Node for this page."
  end

  page.destroy
  puts "... destroyed page."

end
