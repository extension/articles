# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Communitylistconnection < ActiveRecord::Base

  CONNECTIONTYPES = {'leaders' => 'Mailing list for Community Leaders',
                     'joined' => 'Mailing list for those that have joined the community',
                     'interested' => 'Mailing list for those that want to join, or are interested in the community'}
                     
           
  belongs_to :list
  belongs_to :community
  
end