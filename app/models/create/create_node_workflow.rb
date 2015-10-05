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
end
