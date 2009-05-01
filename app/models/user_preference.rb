# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class UserPreference < ActiveRecord::Base
  belongs_to :user
  
  ALL = "all"
  FILTER_CATEGORY_ID = 'filter.category.id'
  SEARCH_LIMIT = 'search_limit'
  WATCH_MY_FAQ = 'watch_my_faq'
  SHOW_PUBLISHING_CONTROLS = 'show_publishing_controls'
  AAE_LOCATION_ONLY = 'aae_location_only'
  AAE_COUNTY_ONLY = 'aae_county_only'
  FILTER_WIDGET_ID = 'filter.widget.id'
  AAE_FILTER_SOURCE = 'expert.source.filter'
  AAE_FILTER_CATEGORY = 'expert.category.filter'
  AAE_FILTER_COUNTY = 'expert.county.filter'
  AAE_FILTER_LOCATION = 'expert.location.filter'
end
