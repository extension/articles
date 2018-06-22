# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

class Person < ActiveRecord::Base

  def fullname
    return "#{self.first_name} #{self.last_name}"
  end

  def signin_allowed?
    !self.retired?
  end

  def self.systemuserid
    1
  end

end
