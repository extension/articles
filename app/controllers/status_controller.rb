# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

class StatusController < ApplicationController
  session :off
  
  def version
    @deploy = Hash.new
    fname = 'REVISION'
    if File.exists?(fname)
      stat = File.stat(fname)
      @deploy['date'] = stat.ctime
      @deploy['revision'] = File.read(fname)
      @deploy['userid'] = stat.uid
      userinfo = Etc.getpwuid(stat.uid)
      @deploy['username'] = userinfo.name
    end
    # tests db connection
    @deploy['schema_version'] = ActiveRecord::Base.connection.select_value('SELECT MAX(CONVERT(version,UNSIGNED)) FROM schema_migrations').to_i
    render(:layout => false)
  end
  
  def crash
    render(:layout => false,:template => 'status/version')
  end
  
  # prints out session information
  def debug
  end

end