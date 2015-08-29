# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

module ImageauditHelper

  def imageaudit_link(image,options = {})
    link_to(image_tag(image.src_path, class: 'imageaudit'), image.src_path, options).html_safe
  end

  def imageaudit_sourcelink(image)
    if(image.source == 'copwiki')
      # if(!image.create_fid.nil?)
      #   ("copwiki<br/>" + link_to('create image data',"http://#{Settings.create_site}/file/#{image.create_fid}")).html_safe
      # else
        'copwiki'
      # end
    elsif(image.source == 'create')
      link_to('create',"http://#{Settings.create_site}/file/#{image.source_id}").html_safe
    else
      ''
    end
  end

  def percentage_display(partial,total)
    if(total == 0)
      'n/a'
    else
      number_to_percentage((partial /total) * 100, :precision => 1 )
    end

  end



end
