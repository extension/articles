# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

module ApplicationHelper

  def selected_tab_if(tab_name)
    'class="selected"' if @selected_tab == tab_name
  end

  def is_submitter(question_response)
    if question_response.submitter
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
    '<abbr class="' + class_name + '" title="' + time.strftime(mformat) + '">' + time.strftime(mdisplay) + '</abbr>'.html_safe
  end

  def expanded_time_print(time)
    time.strftime("%B %d, %Y")
  end

  def humane_date(time)
     if(time.blank?)
       ''
     else
       time.strftime("%B %e, %Y, %l:%M %p %Z")
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

  def bootstrap_alert_class(type)
    baseclass = "alert"
    case type
    when :alert
      "#{baseclass} alert-warning"
    when :warning
      "#{baseclass} alert-warning"
    when :error
      "#{baseclass} alert-danger"
    when :failure
      "#{baseclass} alert-warning"
    when :notice
      "#{baseclass} alert-info"
    when :success
      "#{baseclass} alert-success"
    else
      "#{baseclass} #{type.to_s}"
    end
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

  def get_wow_text(page)
    if(page.summary.blank?)
      # the reason for this is the page is likely readonly from a collection
      newpage = Page.find(page.id)
      newpage.set_summary(true)
    else
      page.summary
    end
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

  def default_location_id(fallback_location_id = nil)
    if(@personal[:location].blank?)
      if(fallback_location_id.blank?)
        return ''
      else
        return fallback_location_id
      end
    else
      return @personal[:location].id
    end
  end


  def default_county_id(fallback_county_id = nil)
    if(@personal[:county].blank?)
      if(fallback_county_id.blank?)
        return ''
      else
        return fallback_county_id
      end
    else
      return @personal[:county].id
    end
  end


  def content_widget_styles
    css_data = File.new("#{Rails.root}/public/stylesheets/content_widget.css", 'r').read
    '<br /><style type="text/css" media="screen">' + css_data + '</style>'.html_safe
  end

end
