# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class CreateFile < ActiveRecord::Base
  # connects to the create database
  self.establish_connection :create
  self.set_table_name 'file_managed'
  self.set_primary_key "fid"
  self.inheritance_column = "inheritance_type"



  def self.create_or_update_from_hosted_image(hosted_image)
    return nil if !File.exists?(hosted_image.filesys_path)


    attributes = {uid: 1,
                  status: 1,
                  filesize: hosted_image.filesize,
                  filemime: hosted_image.filemime.type,
                  filename: hosted_image.filename,
                  type: hosted_image.filetype}
    begin
      cf = self.create(attributes.merge({uri: hosted_image.create_uri,timestamp: Time.now.utc.to_i}))
      hosted_image.update_column(:create_fid, cf.fid) if cf.valid?

    rescue ActiveRecord::RecordNotUnique
      cf = self.where(uri: hosted_image.create_uri).first
      cf.update_attributes(attributes) if !cf.nil?
    end

    if(!cf.nil? and cf.valid?)
      ['data','revision'].each do |data_or_revision|
        self.connection.execute(create_copyright_update_query(hosted_image,cf.id,data_or_revision))
        self.connection.execute(create_description_update_query(hosted_image,cf.id,data_or_revision))
      end
    end
    cf
  end

  def self.create_copyright_update_query(hosted_image,fid,data_or_revision)
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{CreateFile.connection.current_database}.field_#{data_or_revision}_field_copyright (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_copyright_value, field_copyright_format)
    SELECT 'file',
           #{ActiveRecord::Base.quote_value("#{hosted_image.filetype}")},
           0,
           #{fid},
           #{fid},
           'und',
           0,
           #{ActiveRecord::Base.quote_value(hosted_image.copyright)},
           'NULL'
    ON DUPLICATE KEY
    UPDATE field_copyright_value=#{ActiveRecord::Base.quote_value(hosted_image.copyright)}
    END_SQL
    query
  end

  def self.create_description_update_query(hosted_image,fid,data_or_revision)
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{CreateFile.connection.current_database}.field_#{data_or_revision}_field_media_description (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_media_description_value, field_media_description_format)
    SELECT 'file',
           #{ActiveRecord::Base.quote_value("#{hosted_image.filetype}")},
           0,
           #{fid},
           #{fid},
           'und',
           0,
           #{ActiveRecord::Base.quote_value(hosted_image.description)},
           'NULL'
    ON DUPLICATE KEY
    UPDATE field_media_description_value=#{ActiveRecord::Base.quote_value(hosted_image.description)}
    END_SQL
    query
  end


end
