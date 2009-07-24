# 
# this seems silly to me, copying from pubsite code - jayoung
# 
require 'uri'

module URI
  
  def swap_path!(new_path)
    self.path = new_path
    self
  end
end