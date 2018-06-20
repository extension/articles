# credits: http://www.distancetohere.com/validating-url-in-ruby-on-rails-3/

class UriValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    if(!options[:format].nil? and !options[:format].is_a?(Regexp))
      raise(ArgumentError, "A regular expression must be supplied as the :format option of the options hash") 
    end

    begin 
      uri = URI.parse(value)
      if(uri.class != URI::HTTP and uri.class != URI::HTTPS)
        object.errors.add(attribute, 'only http and https protocols are valid') and false
      end
      if(uri.host.nil?)
        object.errors.add(attribute, 'must have a valid host') and false
      end
    rescue URI::InvalidURIError
      object.errors.add(attribute, 'is invalid') and false
    end
  end
end

# optional at some point- could also test the URL via http
# probably want to check the format with regexp first:
# configuration = {:format => URI::regexp(%w(http https)) }
# configuration.update(options)
# 
#   case Net::HTTP.get_response(URI.parse(value))
#     when Net::HTTPSuccess,Net::HTTPRedirection then true
#     else object.errors.add(attribute, configuration[:message]) and false
#   end
# rescue # Recover on DNS failures..
#   object.errors.add(attribute, configuration[:message]) and false
# end