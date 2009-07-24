#
# this seems silly to me, copying from pubsite code - jayoung
#
class String
  def absolute_url?
    %w{ http https ftp ftps }.each do |prefix|
      return true if self.starts_with?(prefix)
    end
    false
  end
  
  def relative_url?
    not self.absolute_url?
  end
  
  def fragment_only_url?
    self.starts_with?('#')
  end
  
  def extension_url?
    self.include?('extension.org')
  end  
end