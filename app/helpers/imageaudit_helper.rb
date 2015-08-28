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
      if(!image.create_fid.nil?)
        ("copwiki<br/>" + link_to('create image data',"http://create.extension.org/file/#{image.create_fid}")).html_safe
      else
        'copwiki'
      end
      elsif(image.source == 'create')
      link_to('create',"http://create.extension.org/file/#{image.source_id}").html_safe
    else
      ''
    end
  end


end
