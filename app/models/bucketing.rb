# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


# join class for articles <=> content buckets

class Bucketing < ActiveRecord::Base
  belongs_to :content_bucket, :foreign_key => "content_bucket_id", :class_name => "ContentBucket"
  belongs_to :page
end
