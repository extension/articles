# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class ImageDataLink < ActiveRecord::Base
  belongs_to :link
  belongs_to :image_data
end
