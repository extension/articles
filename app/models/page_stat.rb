# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding from the eXtension Foundation
# === LICENSE:
#
#  see LICENSE file

class PageStat < ActiveRecord::Base
  belongs_to :page

  # hardcoded right now
  START_DATE = Date.parse('2014-08-24')
  END_DATE = Date.parse('2015-08-24')

  PERCENTILES = [99,95,90,75,50,25,10]

  scope :eligible_pages, -> {where("weeks_published > 0")}
  scope :viewed, -> (view_base = 1) {eligible_pages.where("mean_unique_pageviews >= ?",view_base)}
  scope :unviewed, -> (view_base = 1) {eligible_pages.where("mean_unique_pageviews < ?",view_base)}
  scope :missing, -> {eligible_pages.where("mean_unique_pageviews = 0")}


  def update_stats
    p = self.page
    self.update_attributes(p.page_stat_attributes)
  end

  def self.rebuild_stats
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    Page.order(:id).all.each do |p|
      if(ps = self.where(page_id: p.id).first)
        ps.update_attributes(p.page_stat_attributes)
      else
        ps = self.create(p.page_stat_attributes.merge({:page_id => p.id}))
      end
    end
  end


  def self.overall_stat_attributes
      pages = self.eligible_pages.count
      viewed_pages = self.viewed.count
      missing_pages = self.missing.count
      viewed_percentiles = []
      PERCENTILES.each do |percentile|
        viewed_percentiles << self.pluck(:mean_unique_pageviews).nist_percentile(percentile)
      end

      attributes = {}
      attributes[:pages] = pages
      attributes[:viewed_pages] = viewed_pages
      attributes[:missing_pages] = missing_pages
      attributes[:viewed_percentiles] = viewed_percentiles
      attributes[:image_links] = Link.image.count("distinct links.id")

      copwiki_images = HostedImage.from_copwiki.published_count
      create_images = HostedImage.from_create.published_count
      hosted_images = HostedImage.published_count
      copwiki_images_with_copyright = HostedImage.from_copwiki.with_copyright.published_count
      create_images_with_copyright = HostedImage.from_create.with_copyright.published_count
      hosted_images_with_copyright = HostedImage.with_copyright.published_count

      attributes[:copwiki_images] = copwiki_images
      attributes[:create_images] = create_images
      attributes[:hosted_images] = hosted_images
      attributes[:copwiki_images_with_copyright] = copwiki_images_with_copyright
      attributes[:create_images_with_copyright] = create_images_with_copyright
      attributes[:hosted_images_with_copyright] = hosted_images_with_copyright
      attributes
    end

end
