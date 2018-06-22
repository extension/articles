# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
# see LICENSE file

class CreateNodeWorkflowEvent < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name='node_workflow_events'
  self.primary_key="weid"

  # workflow events
  MOVED_TO_DRAFT = 1
  READY_FOR_REVIEW = 2
  REVIEWED = 3
  READY_TO_PUBLISH = 4
  PUBLISHED = 5
  UNPUBLISHED = 6
  INACTIVE = 7
  ACTIVATED = 8
  READY_FOR_COPYEDIT = 9
  REDIRECTED = 10

  DESCRIPTIONS = {
    MOVED_TO_DRAFT => 'moved back to draft',
    READY_FOR_REVIEW => 'marked ready for review',
    REVIEWED => 'reviewed',
    READY_TO_PUBLISH => 'marked ready for publish',
    PUBLISHED => 'published',
    UNPUBLISHED => 'unpublished',
    INACTIVE => 'made inactive',
    ACTIVATED => 'activated',
    READY_FOR_COPYEDIT => 'marked ready for copy edit',
    REDIRECTED => 'redirected in articles'
  }


end
