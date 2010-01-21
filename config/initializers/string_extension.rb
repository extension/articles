class String
  
  # patch string so that we can use this in controllers and elsewhere
  # see comments of:  http://apidock.com/rails/ActionView/Helpers/SanitizeHelper/sanitize
  def sanitize(options={})
    ActionController::Base.helpers.sanitize(self, options)
  end
  
end