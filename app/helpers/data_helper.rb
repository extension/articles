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
  
  def link_to_community(community)
    if community.tags.empty?
      return community.public_name
    else
      return link_to(h(community.public_name), site_index_url(:category => community.primary_content_tag_name))
    end
  end
  
  def link_to_page(result)
    params[:controller]
    value = result.send(result.class.representative_field)
    page = result.class.page
    url = self.send(result.class.page+'_page_url', {result.class.representative_field.to_sym => value })
    
    link_to result.title, url
  end
  
  def month_select(date, link_to_current = false, category = nil, state = nil)
    url_params = {}
    url_params.update({:category => category.name}) if category
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
  
  #this might not be used anymore
  def communities_links(faq)
    cats = faq.categories.split(',')
    result = ''
    result = 'Community:' if cats.length == 1
    result = 'Communities:' if cats.length > 1
    
    for cat in cats
      result += ' ' +link_to(cat.strip , category_index_url(:category => cat.strip))
    end
    
    result
  end
  
  def state_select(name, params)
    select(name, :state, Location.states.all.collect {|l| [l.name, l.abbreviation]}, {:selected => params[:state]},{ :onchange => 'update_state(this.value)'})
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