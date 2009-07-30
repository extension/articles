# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


class ChatAccount < ActiveRecord::Base
  belongs_to :user

  before_save  :set_values_from_user
  before_update  :set_values_from_user

  def set_values_from_user
    self.user_id = self.user.id
    self.password = self.user.password
    self.username = self.user.login.downcase
    self.name = self.user.fullname
    self.email = self.user.email
  end
end