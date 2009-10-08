#
# this seems silly to me, copying from pubsite code - jayoung
#
class String
  # TODO: review why we have this
  def absolute_url?
    %w{ http https ftp ftps }.each do |prefix|
      return true if self.starts_with?(prefix)
    end
    false
  end
  
  # TODO: review why we have this
  def relative_url?
    not self.absolute_url?
  end
  
  # TODO: review why we have this
  def fragment_only_url?
    self.starts_with?('#')
  end
  
  # TODO: review why we have this
  def extension_url?
    self.include?('extension.org')
  end  
  
  # this one isn't in the silly list, utilizing the string patching we are doing already
  # patch string so that we can use this in controllers and elsewhere
  # see comments of:  http://apidock.com/rails/ActionView/Helpers/SanitizeHelper/sanitize
  def sanitize(options={})
    ActionController::Base.helpers.sanitize(self, options)
  end
  
end