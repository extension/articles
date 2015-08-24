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

  def community
    @community = PublishingCommunity.find_by_id(params[:id])
    if(@community.nil?)
      return do_404
    end
    @summary_data = @community.community_page_stat.attributes
  end

end
