# === COPYRIGHT:
#  Copyright (c) 2005-2019 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
class MigrationController < ApplicationController
  before_filter :turn_off_resource_areas
  before_filter :www_store_location
  before_filter :set_content_tag_and_community

  layout 'frontporch'

  def migrated_communities
    set_title("Migrated Communities")
    @communities =  PublishingCommunity.migrated.all(:order => 'name')
    render :layout => 'admin'
  end

  def redirects
      content_tag = params[:content_tag]
      @tagged_pages = Page.tagged_with(content_tag_url_display_name(content_tag))
      @wordpress_domain = @community.migrated_domain
  end

end
