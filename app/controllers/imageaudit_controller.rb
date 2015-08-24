# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class ImageauditController < ApplicationController
  before_filter :signin_required
  before_filter :turn_off_resource_areas

  layout 'frontporch'

  def index
    @summary_data = PageStat.overall_stat_attributes
  end


end
