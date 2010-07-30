# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module ApplicationHelper
    
  def selected_tab_if(tab_name)
    'class="selected"' if @selected_tab == tab_name
  end
  
  def is_public_responder(question_response)
    if question_response.public_responder 
      return true 
    else
      return false
    end
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
  
  def with_content_tag?
    if(params[:controller] == 'main' and params[:action] == 'index')
      return {:content_tag => 'all'}
    elsif(!@content_tag.nil?)
      return {:content_tag => @content_tag.name}
    else
      return {:content_tag => 'all'}
    end
  end
  
  def get_filtered_aae_incoming_count
    return SubmittedQuestion.submitted.filtered(@currentuser.aae_filter_prefs).count
  end
  
  def get_total_incoming_questions
    return SubmittedQuestion.submitted.count
  end 
  
  def get_aae_assigned_to_me_count
    return SubmittedQuestion.submitted.filtered({:assignee => @currentuser}).count
  end
  
  def get_aae_resolved_by_me_count
    return SubmittedQuestion.resolved.filtered({:resolved_by => @currentuser}).count
  end
  
  def options_from_categories(selected = nil)
    categories = Array.new

    categories = Category.root_categories.collect { |cat| [cat.name, cat.id] }

    categories.insert(0, [Category::UNASSIGNED, Category::UNASSIGNED])
    categories.insert(0, ["All categories", Category::ALL])

    if selected.kind_of? Category 
      options_for_select(categories, selected.id)
    else
      options_for_select(categories, selected)
    end    
  end
  
  # right now, we're only doing the pretty timezone display mappings for 
  # the major US timezones
  def format_time_zone(tz)
    timezone_map = {"Eastern Time (US & Canada)" => "ET",
    "Central Time (US & Canada)" => "CT",
    "Mountain Time (US & Canada)" => "MT",
    "Pacific Time (US & Canada)" => "PT"}
    if timezone_map[tz]
      return timezone_map[tz]
    else
      return tz
    end
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
  
  # used to take a date_time 
  # and takes a new time zone along with the timezone you want to convert from 
  # and converts the date-time to the date-time of the new time zone.
  # time zones are taken in the format of time zone names in ActiveSupport::TimeZone 
  # ie. 'Eastern Time (US & Canada)'
  # it returns an ActiveSupport::TimeWithZone object and you'll be able to access it's properties 
  # like for example 'time_zone_obj.time_zone.name' you can see more in the rails documentation
  def convert_timezone(new_zone, old_zone, date_time_to_convert)
    if !new_zone.blank? and !old_zone.blank? and !date_time_to_convert.blank?
      begin
        return Time.parse("#{date_time_to_convert} #{old_zone}").in_time_zone("#{new_zone}")
      rescue Exception => e
        return nil
      end
    else
      return nil
    end
  end
  
  # http://blog.macromates.com/2006/wrapping-text-with-regular-expressions/
  def wrap_text(txt, col=120)
    txt.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/,
      "\\1\\3\n") 
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
  
  def prepare_aae_signature(response)
    if response.signature.blank?
      return ''
    else
      return '<br />' + format_text_for_display(response.signature)
    end   
  end

  def format_text_for_display(content)
    return word_wrap(simple_format(auto_link(content, :all, :target => "_blank"))) 
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
  
  def get_title(html_content)
    return "" unless html_content
    sushi = Nokogiri::HTML::DocumentFragment.parse(html_content)
    text = sushi.css("div#wow").text
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
        if !community.topic.nil?
          selected_arr.push(topic.id) if community.public_topic_id == topic.id
        end
      end
    end
    topic_mapping = topics.map {|t| [t.name,t.id]}
    topic_mapping.unshift(['',''])
    option_html = options_for_select(topic_mapping, selected_arr)
    select_tag('community[public_topic_id]', option_html, {})
  end
  
  def incomplete_profile(action)
    return '<h3>'+
          'Your profile must be complete to '+action+'.  '+link_to_unless_current("Complete profile.", edit_user_url(:id => current_user.id) )+
          '</h3>'
  end
    
  def render_inline_logo(options = {})
    logo = options[:logo]
    return '' unless logo && logo.image?
    show_thumbnail = (options[:show_thumbnail].nil? ? false : options[:show_thumbnail])
    alt_text = (options[:alt_text].nil? ? logo.filename : options[:alt_text])
    url = "#{logo_path({:file => logo.filename})}"
    url += "?thumb=true" if show_thumbnail
    image_tag(url, :width => logo.width, :alt => alt_text)
  end
    
  def link_by_count(count,text,params,htmloptions={})
    (count.to_i == 0) ? text : link_to(text,params,htmloptions)
  end
  
  
end
