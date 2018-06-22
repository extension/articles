# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
# see LICENSE file

class CreateNodeWorkflow < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name='node_workflow'
  self.primary_key="nwid"

  DRAFT = 1
  REVIEW_READY = 2
  UNDER_REVIEW = 3
  PUBLISH_READY = 4
  PUBLISHED = 5
  COPYEDIT_READY = 6
  REDIRECTED = 7

  DESCRIPTIONS = {
    DRAFT => 'draft',
    REVIEW_READY => 'ready for review',
    UNDER_REVIEW => 'under review',
    PUBLISH_READY => 'ready for publish',
    PUBLISHED => 'published',
    COPYEDIT_READY => 'ready for copy edit',
    REDIRECTED => 'redirected'
  }

end
