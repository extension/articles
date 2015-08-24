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

  def pagelist
  end

  def imagelist
    @pagination_params = {}
    @filter_strings = []
    @filtered = false

    if(params[:community_id] and @community = PublishingCommunity.find_by_id(params[:community_id]))
      @pagination_params[:community_id] = params[:community_id]
      @filter_strings << "Community: #{@community.name}"
      @filtered = true
      image_scope = @community.hosted_images
    else
      image_scope = HostedImage.scoped({})
    end

    if(params[:viewed] and TRUE_VALUES.include?(params[:viewed]))
      @pagination_params[:viewed] = params[:viewed]
      @filter_strings << "Viewed images only"
      @filtered = true
      if(@community)
        image_scope = @community.viewed_images.viewed
      else
        image_scope = image_scope.viewed
      end
    else
      if(@community.nil?)
        image_scope = image_scope.linked
      end
    end

    if(params[:copyright] and TRUE_VALUES.include?(params[:copyright]))
      @pagination_params[:copyright] = params[:copyright]
      @filter_strings << "With copyright"
      @filtered = true
      image_scope = image_scope.with_copyright
    end
    @images = image_scope.page(params[:page]).per(10)
  end

  def showimage
    @image = HostedImage.find_by_id(params[:id])
    if(@image.nil?)
      return do_404
    end
  end

  def showpage
    @page = Page.includes(:page_stat).find_by_id(params[:id])
    if(@page.nil?)
      return do_404
    end
    @stats = @page.page_stat
  end


end
