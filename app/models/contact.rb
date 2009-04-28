# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Contact < ActiveRecord::Base
  
  def self.columns() 
    @columns ||= []
  end
  
  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end
  
  def save(validate = true)
    validate ? valid? : true
  end  

  column :typeofcontact, :string
  column :subject, :string
  column :comments, :string
  column :name, :string
  column :email, :string
  column :login, :string
  column :loggedin, :boolean

  validates_presence_of :typeofcontact, :subject, :comments, :name, :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/
  
  
end

