# from: http://robots.thoughtbot.com/catching-json-parse-errors-with-custom-middleware
# to handle the alihack probes
class CatchRackParamErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue MultiJson::LoadError => error
      if env['HTTP_ACCEPT'] =~ /application\/json/
        error_output = "There was a problem in the JSON you submitted: #{error}"
        return [
          400, { "Content-Type" => "application/json" },
          [ { status: 400, error: error_output }.to_json ]
        ]
      else
        raise error
      end
    rescue TypeError => error
      # specifically handle the issue where we have login attempts
      # with crappy parameters blowing up rails
      if(error.message =~ /KeySpaceConstrainedParams/)
        return [400, { "Content-Type" => "text/plain" },
        ["400 Bad Request\n" \
         "You sent something we didn't understand "]]
      else
        raise error
      end
    end
  end
end
