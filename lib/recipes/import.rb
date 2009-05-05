config = Capistrano::Configuration.instance

namespace :darmok do
    
  # The path to the temporary import file
  def import_file_path(type); "#{shared_path}/#{type.to_s}.temp.csv"; end
  
  # Expose the local file location, the remote rake task name for each existing import
  # file
  def import_types
    types = {:import_zipcodes => :zip_file}
    
    # Note, import_ips should always be first to ensure reliable results.
    types.each do |rake_task, file_arg|
      
      # If we were given a file to upload for this import type
      yield rake_task, ENV[file_arg.to_s], rake_task if ENV[file_arg.to_s]
    end
  end
    
  desc <<-DESC
    Take zipcode data files and import them into the remote database.
      cap pubsite:import zip_file=/path/to/zips.csv purge=yes
  DESC
  task :import do
    
    # Make sure we have our necessary command line arguments
    if(ENV['zip_file'].nil?)
      warn <<-WARN
      
        ERROR:
        Please specify the following import file arguments with the path to the import file:
          '-s zip_file=/path/to/zips.csv'
        with an optional purge argument
          '-s purge=yes'
        if you want to overwrite existing zip code date data.
      WARN
      raise Exception, "Could not find zip_file data specified"
    end
    
    # Do some actual work
    transaction { do_import; clear_import }
  end
  
  task :do_import, :roles => :app, :only => { :primary => true } do
    
    # Wipe up after ourselves
    on_rollback {clear_import}
    
    # Upload files to shared app path as temp file
    import_types do |rake_task, local_file|
      
      put(File.read(local_file), import_file_path(rake_task), :mode => 0774)
  
      # Run rake task for import against this temp file location
      run <<-RUN
        cd #{current_path} && rake pubsite:#{rake_task} file='#{import_file_path(rake_task)}' purge=#{ENV['purge']}
      RUN
    end
    
  end
  
  desc "Remove any remnants of the import routine from the remote server"
  task :clear_import, :roles => :app, :only => { :primary => true } do
    
    # Delete all remote temporary import files only if a connection has already been
    # made to any of the servers
    import_types { |rake_task, local_file| run "rm #{import_file_path(rake_task)}" } if not sessions.empty?
  end
end
