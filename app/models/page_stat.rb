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

end
