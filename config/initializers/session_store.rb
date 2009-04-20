# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_darmok_session',
  :secret      => 'b1c69252c451df73002849d0f665ae4978ad3fc4b3d1f0107296009f5e9787c6ad8d0dc66ef3f7b31efe999b2337e0b86cfd31772f2b1e0c4c6f38af04a6341c'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
