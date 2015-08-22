# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class ImageData < ActiveRecord::Base






  def self.update_from_create
    create_database = CreateFile.connection.current_database
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{self.connection.current_database}.#{self.table_name} (source_id, source, filename, path, description, copyright)
    SELECT fid, 'create', filename, uri, field_media_description_value, field_copyright_value
    FROM (
      SELECT fid, filename, uri, field_media_description_value, field_copyright_value
      FROM (
            #{create_database}.file_managed
            LEFT JOIN #{create_database}.field_data_field_media_description
            ON #{create_database}.field_data_field_media_description.entity_type = 'file'
            AND #{create_database}.field_data_field_media_description.entity_id = #{create_database}.file_managed.fid
          )
          LEFT JOIN #{create_database}.field_data_field_copyright
          ON #{create_database}.field_data_field_copyright.entity_type = 'file'
          AND #{create_database}.field_data_field_copyright.entity_id = #{create_database}.file_managed.fid
          WHERE #{create_database}.file_managed.type = 'image'
    ) AS create_image_data
    ON DUPLICATE KEY UPDATE
    filename = create_image_data.filename,
    path = create_image_data.uri,
    description = create_image_data.field_media_description_value,
    copyright = create_image_data.field_copyright_value
    END_SQL

    CreateFile.connection.execute(query)

  end

end
