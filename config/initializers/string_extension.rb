class String
  
  # patch string so that we can use this in controllers and elsewhere
  # see comments of:  http://apidock.com/rails/ActionView/Helpers/SanitizeHelper/sanitize
  def sanitize(options={})
    ActionController::Base.helpers.sanitize(self, options)
  end
  
   # overrides the rails truncate to add [:avoid_orphans]
   # adapted from http://vermicel.li/blog/2009/01/30/awesome-truncation-in-rails.html
   def truncate(length, options={})
     text = self.dup
     options[:omission] ||= "..."

     # support any of:
     #  * ruby 1.9 sane utf8 support
     #  * rails 2.1 workaround for crappy ruby 1.8 utf8 support
     #  * rails 2.2 workaround for crappy ruby 1.8 utf8 support
     # hooray!
     if text
       chars = if text.respond_to?(:mb_chars)
         text.mb_chars
       elsif RUBY_VERSION < '1.9'
         text.chars
       else
         text
       end

       omission = if options[:omission].respond_to?(:mb_chars)
         options[:omission].mb_chars
       elsif RUBY_VERSION < '1.9'
         options[:omission].chars
       else
         options[:omission]
       end

       length_with_room_for_omission = length - omission.length
       if chars.length > length_with_room_for_omission
         result = (chars[/\A.{#{length_with_room_for_omission}}\w*\;?/m][/.*[\w\;]/m]).to_s
         ((options[:avoid_orphans] && result =~ /\A(.*?)\n+\W*\w*\W*\Z/m) ? $1 : result) + options[:omission]
       else
         text
       end
     end
   end
  
end