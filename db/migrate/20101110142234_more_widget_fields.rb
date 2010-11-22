class MoreWidgetFields < ActiveRecord::Migration
  def self.up
    add_column(:widgets,:show_location,:boolean)
    add_column(:widgets,:enable_tags,:boolean)
    add_column(:widgets,:community_id,:integer)
    add_column(:widgets,:location_id,:integer)
    add_column(:widgets,:county_id,:integer)
    rename_column(:widgets,:widgeturl,:old_widget_url)
        
    Widget.reset_column_information
    
    # set location and county for each widget, and write every widget to be
    # http://www.extension.org/widget/tracking/#{trackingcode}
    Widget.all.each do |widget|
      if(widget.old_widget_url =~ %r!https*://\w+\.extension\.org/widget/tracking/(\w+)/(\w+)!)
        # probably has a location
        trackingcode = $1
        location_abbreviation = $2
        if(location = Location.find_by_abbreviation(location_abbreviation))
          widget.location = location
          if(widget.old_widget_url =~ %r!https*://\w+\.extension\.org/widget/tracking/(\w+)/(\w+)/(.+)!)
            # probably has a county
            # unescape due to URL encoded values like Prince%20George's
            county_name = URI.unescape($3)
            # the quote value is here because of quoted values like Prince%20George's
            if(county = County.find(:first, :conditions => "name = #{ActiveRecord::Base.quote_value(county_name)} and location_id = #{location.id}"))
              widget.county = county
            end
          end
        end
        widget.save
      end 
    end
    
    # special case for widget #708 - which has ?location=AL in it
    execute("UPDATE widgets SET location_id = 11 where id = 708")
    
    
    # make sure Bonnie Plants widget is show_location enabled
    execute "UPDATE widgets SET show_location = 1 WHERE fingerprint = '#{Widget::BONNIE_PLANTS_WIDGET}'"

  end

  def self.down
    # no going back.
  end
end
