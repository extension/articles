# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class LogoController < ApplicationController

  def display
    begin
      @logo = Logo.find_by_filename(params[:file].to_s + "." + params[:format].to_s)
      @logo = Logo.find(params[:file]) unless @logo
      if(@logo.nil?)
        send_data(data, :filename => "unknown.gif", :type => "image/gif", :disposition => 'inline')
      else
        show_thumbnail = (params[:thumb] == "true")
        respond_to do |format|
          format.html { render :action => 'show', :layout => false }
          format.xml  { render :xml => @logo.to_xml }
          format.jpg  { send_data(@logo.image_data(show_thumbnail), 
                                  :type  => @logo.content_type, 
                                  :filename => @logo.filename, 
                                  :disposition => 'inline') }
          format.gif  { send_data(@logo.image_data(show_thumbnail), 
                                  :type  => @logo.content_type, 
                                  :filename => @logo.filename, 
                                  :disposition => 'inline') }
          format.png  { send_data(@logo.image_data(show_thumbnail), 
                                  :type  => @logo.content_type, 
                                  :filename => @logo.filename, 
                                  :disposition => 'inline') }
        end
      end
    rescue Exception => err
      logger.debug(err.message)
      logger.debug(err.backtrace)
    
      file = "#{RAILS_ROOT}/public/images/loading.gif"
      data = File.new(file, 'r').read
      send_data(data, :filename => "unknown.gif", :type => "image/gif", :disposition => 'inline')
    end
  end
end