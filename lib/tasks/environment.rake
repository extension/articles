%w[dev].each do |server|
  desc "Runs the following task on the #{server} server" 
  task server do
    puts "  * server: setting server environment"
    SERVER =  ENV['SERVER'] = server
    RAILS_ENV =  ENV['RAILS_ENV'] = "production"
  end
end

%w[production development].each do |env|
  task env do
    RAILS_ENV =  ENV['RAILS_ENV'] = env
  end
end

%w[console tail_logs].each do |act|
  task act do
    ENV['ACTION'] = act
  end
end
