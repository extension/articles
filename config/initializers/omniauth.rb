# omniauth setup
Rails.application.config.middleware.use OmniAuth::Builder do
  require 'omniauth-openid'
  require 'openid/store/filesystem'
  provider :open_id,  :store => OpenID::Store::Filesystem.new("#{Rails.root}/tmp/omniauth"), :name => 'people', :identifier => 'https://people.extension.org'
end

