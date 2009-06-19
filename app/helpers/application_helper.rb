# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


module ApplicationHelper
  
  def social_network_class(networkname)
    SocialNetwork::NETWORKS.keys.include?(networkname) ? networkname : 'other'
  end
  
  def selected_tab_if(tab_name)
    'class="selected"' if @selected_tab == tab_name
  end
    
  def county_offices_link
    return nil unless @county_link
    
    "<p class=\"description\">#{link_to 'Contact your local extension office &raquo', @county_link.office_link}</p>"
  end
  
  #old time print
  def micro_time_print(time, class_name)
    return "" unless time
    day_fmt = "%Y%m%d"
    day_and_time_fmt = "%Y-%m-%dT%H:%M:%S" # ISO 8601
    day_display = "%B %d, %Y"
    day_and_time_display = "%B %d, %Y at %l:%M %p"
    case class_name
      when 'published', 'updated'
        mformat = day_fmt
        mdisplay = day_display
      when 'dtstart'
        if time.hour == 0
          mformat = day_fmt
          mdisplay = day_display
        else
          mformat = day_and_time_fmt
          mdisplay = day_and_time_display
        end
      when 'dtend'
        if time.hour == 0
          mformat = day_fmt
          mdisplay = day_display
        else
          mformat = day_and_time_fmt
          mdisplay = day_and_time_display
        end
    end
    '<abbr class="' + class_name + '" title="' + time.strftime(mformat) + '">' + time.strftime(mdisplay) + '</abbr>'
  end
  
  def time_print(time)
    time.strftime("%m.%d.%y")
  end
  
  def expanded_time_print(time)
    time.strftime("%B %d, %Y")
  end
  
  def humane_date(time)
     time.strftime("%B %e, %Y, %l:%M %p")
  end
    
  def article_summary(content)
    return nil unless content
    ptags = Regexp.new('<p>(.+?)<\/p>', Regexp::MULTILINE)
    find_sum = Regexp.new(Regexp.escape('<div id="summary" class="printme toc">') + "(.*?)" + Regexp.escape("</div>"), Regexp::MULTILINE)
    
    summary_match = find_sum.match(content)
    
  	if summary_match
  	  summary = summary_match[1]
  	else
      match = ptags.match(content)
      clean_content =  match ? strip_tags(match[1]) : ""
      summary = word_truncate(clean_content)
    end
    
    return summary
  end
  
  private
  
  def word_truncate(string, word_count=60, threshold=80)
    words = string.split(/\s+/)
    
    if words.length < threshold
      result = string
    else
      result = words[0 .. word_count].join(" ") + " ..."
    end
    
    return result
  end
    
  def truncate_at_word(text, length = 30, truncate_string = '...' )
    if text.nil? then return end
    l = length - truncate_string.length
    return text if text.length < length
    removed = text[0,l] 
    last_index = removed.rindex(' ')
    return removed unless last_index
    return removed[0, last_index]+truncate_string
  end
  
  def strip_title(text)
    return "" unless text
    idx = text.index(/\n/)
    text = text[idx, text.length] if idx
    return text
  end
  
  def get_title(text)
    return "" unless text
    idx = text.index(/\n/)
    text = text[0,idx] if idx
    return text
  end
  
  def select_category_tag(name, options ={}, selected_value =  nil)
    option_tags = ''
    Category.find_all.each{|category|
      option_tags << '<option value="'+category.id.to_s+'" '+(selected_value == category.id ? ' SELECTED' : '')+'>'+category.name+'</option>'
    }
    option_tags += '</option>'
    select_tag(name, option_tags, options)
  end
    
  def select_tag_for_community(options = {})
    tags = Tag.find(:all, :order => 'name').delete_if{|t| t.community}

    option_html = options_for_select(tags.map {|t| [t.name,t.id]})
    
    select_tag('tag_id', option_html, options)
    
  end
  
  def select_tag_for_topic(community = nil)
    topics = Topic.find :all
    selected_arr = []
    for topic in topics
      if community
        selected_arr.push(topic.id) if community.topic_id == topic.id
      end
    end
    topic_mapping = topics.map {|t| [t.name,t.id]}
    topic_mapping.unshift(['',''])
    option_html = options_for_select(topic_mapping, selected_arr)
    select_tag('community[topic_id]', option_html, {})
  end
  
  def incomplete_profile(action)
    return '<h3>'+
          'Your profile must be complete to '+action+'.  '+link_to_unless_current("Complete profile.", edit_user_url(:id => current_user.id) )+
          '</h3>'
  end
    
  def render_inline_image asset, show_thumbnail = false
    return "<img alt='error'></img>" unless asset && asset.image?
    url = "#{asset_path(asset.filename)}"
    url += "?thumb=true" if show_thumbnail
    image_tag url
  end
  
  def social_network_name(social_network)
    SocialNetwork::NETWORKS.keys.include?(social_network.network) ? SocialNetwork::NETWORKS[social_network.network][:displayname] : social_network.displayname
  end
  
  def social_network_link(social_network)
    if(!social_network.accounturl.blank?)
      begin
        accounturi = URI.parse(URI.escape(social_network.accounturl))
      rescue
        return social_network.accountid
      end
      if(accounturi.scheme.nil?)
        uristring = 'http://'+social_network.accounturl
      else
        uristring = social_network.accounturl
      end
      return "<a href=\"#{uristring}\">#{social_network.accountid}</a>"
    else
      return social_network.accountid
    end
  end
  
end
