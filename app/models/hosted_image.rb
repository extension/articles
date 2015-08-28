# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class HostedImage < ActiveRecord::Base
  has_many :hosted_image_links
  has_many :links, :through => :hosted_image_links
  has_many :linkings, :through => :links
  has_many :pages, :through => :linkings
  has_many :page_stats, :through => :pages

  scope :from_copwiki, -> {where(source: 'copwiki')}
  scope :from_create, -> {where(source: 'create')}
  scope :with_copyright, -> {where("copyright IS NOT NULL")}


  def filemime
    MimeMagic.by_magic(File.open(self.filesys_path))
  end

  def filesize
    File.size(self.filesys_path)
  end

  def filetype
    case self.filemime.mediatype
    when 'application'
      'document'
    when 'image'
      self.filemime.mediatype
    when 'video'
      self.filemime.mediatype
    when 'audio'
      self.filemime.mediatype
    else
      'undefined'
    end
  end


  def self.linked
    joins(:hosted_image_links).uniq
  end

  def self.viewed
    joins(:page_stats).where("page_stats.mean_unique_pageviews >= 1").uniq
  end

  def filesys_path
    if(self.source == 'copwiki')
      "#{Rails.root}/public/mediawiki/files#{self.path}"
    else
      ''
    end
  end

  def create_uri
    if(source == 'create')
      self.path
    elsif(source == 'copwiki')
      "public://w#{self.path}"
    end
  end

  def src_path
    if(self.source == 'copwiki')
      URI.escape("http://create.extension.org/sites/default/files/w#{self.path}")
    elsif(self.source == 'create')
      if(%r{^public:} =~ self.path)
        URI.escape(self.path.gsub('public://','http://create.extension.org/sites/default/files/'))
      else
        ''
      end
    else
      ''
    end
  end

  def self.published_count
    joins(:hosted_image_links).count('distinct hosted_image_links.hosted_image_id')
  end

  def self.viewed_count
    joins(:page_stats).where("page_stats.mean_unique_pageviews >= 1").count("distinct hosted_images.id")
  end

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


  def self.link_by_path(matchpath,link_id,source)
    case source
      when 'copwiki'
        # somehow there are /a/aa/filename/some_other_file_name paths
        matchpath_breakdown = matchpath.split('/')
        searchpath = "/#{matchpath_breakdown[1]}/#{matchpath_breakdown[2]}/#{matchpath_breakdown[3]}"
        if(id = self.where(path: searchpath).where(source: 'copwiki').first)
          begin
            id.hosted_image_links.create(link_id: link_id)
          rescue ActiveRecord::RecordNotUnique
            # already linked
          end
        end
      when 'create'
        if(id = self.where(path: "public://#{matchpath}").where(source: 'create').first)
          begin
            id.hosted_image_links.create(link_id: link_id)
          rescue ActiveRecord::RecordNotUnique
            # already linked
          end
        end
      else
        # nothing for now
    end
  end



end
