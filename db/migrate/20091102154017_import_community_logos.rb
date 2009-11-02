class ImportCommunityLogos < ActiveRecord::Migration
  require 'action_controller'
  require 'action_controller/test_process.rb'

  def self.up
    # modify logos table
    remove_column :logos, "type"  # not used apparently
    add_column :logos, "logotype", :integer, :default => 0 # so that we can filter sponsor advertisements
    execute "UPDATE logos set logotype = #{Logo::SPONSOR}"  
    Community.reset_column_information  

    # institutions first
    Community.institutions.find(:all).each do |i|
      gif = "#{Rails.root.to_s}/public/images/logos/universities/#{i.institution_code}.gif"
      jpg = "#{Rails.root.to_s}/public/images/logos/universities/#{i.institution_code}.jpg"
      if(File.exists?(gif))
        @logo = Logo.new(:uploaded_data => ActionController::TestUploadedFile.new(gif, 'image/gif'))
      elsif(File.exists?(jpg))
        @logo = Logo.new(:uploaded_data => ActionController::TestUploadedFile.new(jpg, 'image/jpeg'))
      end
      @logo.logotype = Logo::COMMUNITY
      @logo.save
      i.update_attribute('logo_id',@logo.id)
    end
    
    # now copads
    Community.notinstitutions.public_list.find(:all).each do |c|
      content_tag_name = c.primary_content_tag_name
      if(!content_tag_name.nil?)
        file_name = content_tag_name.gsub(/[,_]/,'').gsub(/ /,'_').downcase
        gif = "#{Rails.root.to_s}/public/images/layout/copad_#{file_name}.gif"
        jpg = "#{Rails.root.to_s}/public/images/layout/copad_#{file_name}.jpg"
        if(File.exists?(gif))
          @logo = Logo.new(:uploaded_data => ActionController::TestUploadedFile.new(gif, 'image/gif'))
        elsif(File.exists?(jpg))
          @logo = Logo.new(:uploaded_data => ActionController::TestUploadedFile.new(jpg, 'image/jpeg'))
        end
        @logo.logotype = Logo::COMMUNITY
        @logo.save
        c.update_attribute('logo_id',@logo.id)
      end
    end
  end

  def self.down
  end
end
