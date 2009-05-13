# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# The Tag model. This model is automatically generated and added to your app if you run the tagging generator included with has_many_polymorphs.

class ArticleBucket < ActiveRecord::Base
  belongs_to :article
  belongs_to :content_bucket
end
