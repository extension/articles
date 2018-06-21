# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
# see LICENSE file

class CreateNode < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name='node'
  self.primary_key="nid"
  self.inheritance_column = "none"
  bad_attribute_names :changed


  def unpublish(mark_inactive = true)
    if(cnw = CreateNodeWorkflow.where(node_id: self.nid).last)
      unix_timestamp = Time.now.utc.to_i
      # Note: setting 'unpublished at' to nil is a hack to
      # keep it out of the deleted items atom feed
      cnw.update_attributes(active: false,
                            status_text: 'Draft',
                            status: 1,
                            review_count: 0,
                            draft_status: nil,
                            draft_status_text: nil,
                            published_at: nil,
                            unpublished_at: nil,
                            published_revision_id: nil,
                            changed: unix_timestamp)

      # need some workflow events
      CreateNodeWorkflowEvent.create(node_id: self.nid,
                                     node_workflow_id: cnw.nwid,
                                     user_id: 1,
                                     revision_id: cnw.current_revision_id,
                                     event_id: CreateNodeWorkflowEvent::UNPUBLISHED,
                                     description: 'unpublished',
                                     created: unix_timestamp)
      if(mark_inactive)
        CreateNodeWorkflowEvent.create(node_id: self.nid,
                                       node_workflow_id: cnw.nwid,
                                       user_id: 1,
                                       revision_id: cnw.current_revision_id,
                                       event_id: CreateNodeWorkflowEvent::INACTIVE,
                                       description: 'made inactive',
                                       created: unix_timestamp + 1)
      end
      true
    else
      false
    end
  end

  def mark_as_redirected(redirected_by)
    # TODO:
  end

  def inject_unpublish_notice(unpublish_date = Date.today)
    if(body = CreateFieldDataBody.where(bundle: self.type).where(entity_id: self.nid).first)
      body_block = <<-END_TEXT.gsub(/\s+/, " ").strip
      <div id="content_removal_notes" style="background: #f47c28;border:1px solid #000;color:#000;">
      <p>On #{unpublish_date.strftime('%B %e, %Y')}, this content was automatically unpublished and marked as inactive.
      Please feel free to rework this page, along with properly indicating the copyright for all
      included images and republish it as appropriate.</p>
      <p>Do not hesitate to <a href="http://create.extension.org/node/99714">Contact
      our Community Support staff</a> with any questions you may have.</p></div>
      <br/>
      END_TEXT

      query = <<-END_SQL.gsub(/\s+/, " ").strip
      UPDATE #{CreateFieldDataBody.table_name}
      SET body_value = #{ActiveRecord::Base.quote_value(body_block + body.body_value)}
      WHERE bundle = '#{self.type}' AND entity_id = #{self.nid}
      END_SQL
      body.connection.execute(query)
      true
    else
      false
    end
  end

  def inject_redirect_notice(redirected_by, unpublish_date = Date.today)
    if(body = CreateFieldDataBody.where(bundle: self.type).where(entity_id: self.nid).first)
      body_block = <<-END_TEXT.gsub(/\s+/, " ").strip
      <div id="content_removal_notes" style="background: #f47c28;border:1px solid #000;color:#000;">
      <p>On #{unpublish_date.strftime('%B %e, %Y')}, this content was redirected by #{redirected_by.fullname}.</p>
      <p>This page cannot be republished to articles.extension.org.</p>
      <p>Do not hesitate to <a href="http://create.extension.org/node/99714">Contact
      our Community Support staff</a> with any questions you may have.</p></div>
      <br/>
      END_TEXT

      query = <<-END_SQL.gsub(/\s+/, " ").strip
      UPDATE #{CreateFieldDataBody.table_name}
      SET body_value = #{ActiveRecord::Base.quote_value(body_block + body.body_value)}
      WHERE bundle = '#{self.type}' AND entity_id = #{self.nid}
      END_SQL
      body.connection.execute(query)
      true
    else
      false
    end
  end

end
