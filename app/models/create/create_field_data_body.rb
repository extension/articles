# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
# see LICENSE file

class CreateFieldDataBody < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.table_name='field_data_body'
end
