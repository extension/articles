# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class StatusController < ApplicationController
  session :off
  
  def version
    @deploy = Hash.new
    @deploy['version'] = AppVersion.version
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
  
  def debug
    
  end
  
end