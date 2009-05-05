class Asset < ActiveRecord::Base
  has_attachment  :storage => :db_file, 
                  :content_type => :image,
                  :max_size => 1.megabytes,
                  :thumbnails => { :thumb => '100x100>' },
                  :processor => :rmagick

  validates_as_attachment
  
end
