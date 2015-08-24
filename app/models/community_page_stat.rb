# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding from the eXtension Foundation
# === LICENSE:
#
#  see LICENSE file

class CommunityPageStat < ActiveRecord::Base
  serialize :viewed_percentiles
  belongs_to :publishing_community

  # hardcoded right now
  START_DATE = Date.parse('2014-08-24')
  END_DATE = Date.parse('2015-08-22')



  def update_stats
    pc = self.publishing_community
    self.update_attributes(pc.page_stat_attributes)
  end

  def self.rebuild_stats
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    PageStat.overall_stat_attributes # rebuild all stats
    PublishingCommunity.order(:id).all.each do |p|
      if(ps = self.where(publishing_community_id: p.id).first)
        ps.update_attributes(p.page_stat_attributes)
      else
        ps = self.create(p.page_stat_attributes.merge({:publishing_community_id => p.id}))
      end
    end
  end

end
