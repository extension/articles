# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module InstitutionalLogo

  def existing_university_logo(university_code)
    existing_image("logos/universities/#{university_code}")
  end

  private
  def existing_image(potential_image) 
    return "#{potential_image}.gif" if exists("#{potential_image}.gif")
    return "#{potential_image}.jpg" if exists("#{potential_image}.jpg")
    nil
  end
  
  def exists(potential_image)
    absolute = File.join("public/images/#{potential_image}")
    File.exists?(absolute)
  end
  
end