namespace :admin do
  
  desc "Open up a remote console to #{application} (be sure to set your RAILS_ENV appropriately)"
  task :console, :roles => :app do
    input = ''
    invoke_command "cd #{current_path} && ./script/console #{ENV['RAILS_ENV'] || 'production'}" do |channel, stream, data|
      next if data.chomp == input.chomp || data.chomp == ''
      print data
      channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
    end
  end

  desc "Tail the server logs for #{application}"
  task :tail_logs, :roles => :app do
    run "tail -f #{shared_path}/log/production.log #{shared_path}/log/mongrel.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}" 
      break if stream == :err    
    end
  end
end