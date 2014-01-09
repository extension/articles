# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'fastimage'

module DataHelper

  # TODO:  this is stupid.  a) there's probably a better to get the primary_content_tags and B) if a community has more than one content tag, the news won't be picked up
  # this is crazy, either limit the communities to a single content tag, or find all the content for all the content tags for that community, period.
  def community_select(selected_community,is_events=false)
    make_a_link_params = []
    if(params[:event_state])
      make_a_link_params << "event_state=#{params[:event_state]}"
    end
    
    if(params[:year] and params[:month])
      make_a_link_params << "year=#{params[:year]}"
      make_a_link_params << "month=#{params[:month]}"
    end
    
    if(!make_a_link_params.blank?)
      make_a_link = "\"/\" + this.value + \"/#{params[:action]}?#{make_a_link_params.join('&')}\""
    else
      make_a_link = "\"/\" + this.value + \"/#{params[:action]}\""
    end
    
    communities = PublishingCommunity.launched.ordered("public_name ASC")
    txt = "<select name='community'"
    txt += " onchange='go_category(#{make_a_link})'"
    txt += ">"
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
  
  def link_to_public_community_home(community)
    if(community.nil?)
      return ''
    elsif(community.content_tag_names.empty?)
      return community.public_name
    else
      return "<span class=\"label label-tag\">"  + link_to(h(community.public_name), site_index_url(:content_tag => content_tag_url_display_name(community.primary_content_tag_name))) + "</span>"
    end
  end
  
  def link_to_public_community(community)
    if(community.content_tag_names.empty?)
      return community.public_name
    else
      return link_to(h(community.public_name), site_index_url(:content_tag => content_tag_url_display_name(community.primary_content_tag_name)))
    end
  end
  
  def link_to_preview_community_home(community)
    if(community.content_tag_names.empty?)
      return community.public_name
    else
      return "<span>"  + link_to(h(community.public_name + "Home"), preview_tag_url(:content_tag => content_tag_url_display_name(community.primary_content_tag_name))) + "</span>"
    end
  end
     
  def state_select(name, params)
    if(@content_tag)
      make_a_link = "\"/#{@content_tag.url_display_name}/events?event_state=\" + this.value"
    else
      make_a_link = "\"/all/events?event_state=\" + this.value"
    end
    if(params[:year] and params[:month])
      make_a_link += " + \"&year=#{params[:year]}&month=#{params[:month]}\""
    end
    select(name, :event_state, Location.displaylist.collect{|l| [l.name, l.abbreviation]}.unshift(['All', '']), {:selected => params[:event_state]},{ :onchange => 'go_state(' + make_a_link + ')'})
  end
  
  def first_image(content, placeholder=true)
    return unless content.present?
    image_tag = content.match(/<img[^>]*>/)
    if placeholder
      return '<img src = "/images/frontporch/default_feature_720x340.jpg" alt="" />' unless image_tag
      src = image_tag[0].match(/src="[^"]*"/)[0]
      actual_img_src = src.gsub('src="','')[0..-2]
      actual_img_width = FastImage.size(actual_img_src)
      if actual_img_width.present? && actual_img_width[0].to_f > 550
        return '<img width="'+actual_img_width[0].to_s+'" '+src+' alt="" />'
      else
        return '<img src = "/images/frontporch/default_feature_720x340.jpg" alt="" />'
      end
    else
      return unless image_tag.present?
      src = image_tag[0].match(/src="[^"]*"/)
      if src.present?
        return '<img '+src[0]+' alt="" />'
      end
    end
  end
  
  def first_bio_image(content)
    return unless content
    image_tag = content.match(/<img[^>]*>/)
    return unless image_tag
    src = image_tag[0].match(/src="[^"]*"/)[0]
    return '<img height="135" '+src+' alt="" />'
  end  
end