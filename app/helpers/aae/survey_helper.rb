# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

module Aae::SurveyHelper
  
  def survey_response_checked?(response,method,value)
    if(current = response.send(method))
      current == value
    else
      false
    end
  end
end