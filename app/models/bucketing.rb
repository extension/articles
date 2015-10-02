# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file


# join class for articles <=> content buckets

class Bucketing < ActiveRecord::Base
  belongs_to :content_bucket, :foreign_key => "content_bucket_id", :class_name => "ContentBucket"
  belongs_to :page

  def self.cleanup
    list = self.joins("LEFT join pages on #{self.table_name}.page_id = pages.id").where("pages.id IS NULL")
    list.each do |bucketing|
      bucketing.destroy
    end
    true
  end

end
