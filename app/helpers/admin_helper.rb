module AdminHelper  
  def open_id_info the_user
    return nil unless the_user.identity_url and !the_user.identity_url.blank?
    return "<p>#{link_to "Open ID user", the_user.identity_url}</p>"
  end
end