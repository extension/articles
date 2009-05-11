module DataHelper

  def community_select(selected)
    communities = Community.find_visible_sorted
    #communities.compact!
    txt = "<select name='community' onchange='update_category(this.value)'>"
    txt += '<option value="all"'
    txt += ' selected="selected"' unless selected
    txt += '>All</option>'

    for community in communities
      if !community.tags.empty?
        txt += '<option value="'+community.tags[0].name+'"'
        txt += ' selected' if selected && community.tags[0].name.downcase == selected.name.downcase
        txt += '>'+ community.name+'</option>'
      end
    end
    return txt+'</select>'
  end
  
  def link_to_community(community)
    if community.tags.empty?
      return community.name
    else
      return link_to(h(community.name), site_index_url(:category => community.tags[0].name))
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
    select name, :state, Location.states.unshift(['All', '']), {:selected => params[:state]},{ :onchange => 'update_state(this.value)'}
  end
  
  def first_image(content)
    return unless content
    image_tag = content.match(/<img[^>]*>/)
    return '<img src = "/images/layout/generic_feature.jpg" alt="" />' unless image_tag
    src = image_tag[0].match(/src="[^"]*"/)[0]
    return '<img height="135" '+src+' alt="" />'
  end
  
  def star_ranking(content)
    if content.average_ranking != nil
      image_tag "layout/#{content.average_ranking.to_i.to_s}stars.gif", :alt => "rating: #{content.average_ranking.to_i.to_s} stars"
    else
      "<span class='not_rated'>not rated</span>"
    end
  end

  def community_image(community)
    category_name = community.tags[0].name
    file_name = category_name.gsub(/[,_]/,'').gsub(/ /,'_').downcase
    if File.exists?(File.join('public', "images/layout/copad_#{file_name}.gif"))
      image_tag("/images/layout/copad_#{file_name}.gif", :border => 0, :alt => "") 
    elsif File.exists?(File.join('public', "images/layout/copad_#{file_name}.jpg"))
      image_tag("/images/layout/copad_#{file_name}.jpg", :border => 0, :alt => "")
    end
  end

end