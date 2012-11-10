# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module PagesHelper
  #---------------------------------------------------------------------------
  # For 'date_picker_field' method:
  #---------------------------------------------------------------------------
  #/*
  # ANSI Datepicker Calendar - David Lee 2005

  #  david [at] davelee [dot] com [dot] au

  #  project homepage: http://projects.exactlyoneturtle.com/date_picker/

  #  License:
  #  use, modify and distribute freely as long as this header remains intact;
  #  please mail any improvements to the author
  #*/
  #---------------------------------------------------------------------------
  # date_picker_field modified by NC State below
  #---------------------------------------------------------------------------
  def date_picker_field(object, method, cssclass=nil)
     obj = instance_eval("@#{object}")
     value = obj.send(method)
     display_value = value.respond_to?(:strftime) ? value.strftime('%d %b %Y') : value.to_s
     display_value = 'choose date' if display_value.blank?

     out = hidden_field(object, method)
     out << content_tag('a', display_value, :href => '#',
         :id => "_#{object}_#{method}_link", :class => cssclass,
         :onclick => "DatePicker.toggleDatePicker('#{object}_#{method}'); return false;")
     out << content_tag('div', '', :class => 'date_picker', :style => 'display: none',
                       :id => "_#{object}_#{method}_calendar")
     if obj.respond_to?(:errors) and obj.errors.on(method) then
       ActionView::Base.field_error_proc.call(out, nil) # What should I pass ?
     else
       out
     end
  end

  def homage_link(community)
    link_text = community.homage_name.present? ? community.homage_name : community.public_name
    if(community.homage.present?)
      link_target = community.homage.id_and_link
    else
      link_target = site_index_url(:content_tag => content_tag_url_display_name(community.primary_content_tag_name))
    end
    link_to(link_text,link_target).html_safe
  end

end