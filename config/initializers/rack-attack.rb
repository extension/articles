class Rack::Attack

  # blacklist Typhoeus requests for now
  blacklist('block Typhoeus UA requests') do |req|
    req.user_agent == 'Typhoeus - https://github.com/typhoeus/typhoeus'
  end



end

Rack::Attack.blacklisted_response = lambda do |env|
  # Using 503 because it may make attacker think that they have successfully
  # DOSed the site. Rack::Attack returns 403 for blacklists by default
  [ 503, {}, ['Blocked']]
end
