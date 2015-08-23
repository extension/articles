# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class CreateFile < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.set_table_name 'file_managed'
  self.set_primary_key "fid"


  # used primarily to do insert into image_data
  
end
