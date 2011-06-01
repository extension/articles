# === COPYRIGHT:
# Copyright (c) 2005-2011 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class CreateTaxonomyTerm < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :create
  self.set_table_name 'taxonomy_term_data'
  self.set_primary_key "tid"
end
  