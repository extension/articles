# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module DataHelper

  # TODO:  this is stupid.  a) there's probably a better to get the primary_content_tags and B) if a community has more than one content tag, the news won't be picked up
  # this is crazy, either limit the communities to a single content tag, or find all the content for all the content tags for that community, period.
  def community_select(selected_community)
    communities = Community.launched.ordered("public_name ASC")
    txt = "<select name='community' onchange='update_category(this.value)'>"
    txt += '<option value="all"'
    txt += ' selected="selected"' unless selected_community
    txt += '>All</option>'

    for community in communities
      txt += "<option value='#{community.primary_content_tag_name}'"
      txt += ' selected' if (selected_community && community == selected_community)
      txt += '>'+ community.public_name+'</option>'
    end
    return txt+'</select>'
  end
  
  def link_to_public_community(community)
    if(community.content_tag_names.empty?)
      return community.public_name
    else
      return link_to(h(community.public_name), site_index_url(:content_tag => community.primary_content_tag_name))
    end
  end
  
  def link_to_page(result)
    params[:controller]
    value = result.send(result.representative_field)
    page = result.page
    url = self.send(result.page+'_page_url', {result.representative_field.to_sym => value })
    
    link_to result.title, url
  end
  
  def month_select(date, link_to_current = false, content_tag = nil, state = nil)
    url_params = {}
    if(!content_tag.nil?)
      url_params.update({:content_tag => content_tag.name})
    else
      url_params.update({:content_tag => 'all'})
    end
    url_params.update({:state => state}) if state
    
    if Time.now.year < date.year
      url_params.update({:month => 12, :year => date.year-1})
      txt = link_to((date.year-1).to_s, site_events_month_url(url_params))
    else
      txt = ''
    end
    
    1.upto(12) do |month_number|
      
      month_name = Date::ABBR_MONTHNAMES[month_number].upcase
      if month_number == date.month and not link_to_current
        txt += '<strong>'+month_name+'</strong>'
      else
        url_params.update({:month => month_number, :year => date.year})
        txt += link_to(month_name, site_events_month_url(url_params))
      end
      
    end
    
    url_params.update({:month => 1, :year => date.year+1})
    txt += link_to((date.year+1).to_s, site_events_month_url(url_params))
    txt
  end
    
  def state_select(name, params)
    select(name, :state, Location.displaylist.collect{|l| [l.name, l.abbreviation]}.unshift(['All', '']), {:selected => params[:state]},{ :onchange => 'update_state(this.value)'})
  end
  
  def first_image(content)
    return unless content
    image_tag = content.match(/<img[^>]*>/)
    return '<img src = "/images/layout/generic_feature.jpg" alt="" />' unless image_tag
    src = image_tag[0].match(/src="[^"]*"/)[0]
    return '<img height="135" '+src+' alt="" />'
  end
  
  def community_image(community)
    category_name = community.primary_content_tag_name
    file_name = category_name.gsub(/[,_]/,'').gsub(/ /,'_').downcase
    if File.exists?(File.join('public', "images/layout/copad_#{file_name}.gif"))
      image_tag("/images/layout/copad_#{file_name}.gif", :border => 0, :alt => "") 
    elsif File.exists?(File.join('public', "images/layout/copad_#{file_name}.jpg"))
      image_tag("/images/layout/copad_#{file_name}.jpg", :border => 0, :alt => "")
    end
  end

end