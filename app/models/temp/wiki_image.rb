# === COPYRIGHT:
# Copyright (c) 2005-2015 North Carolina State University
# Developed with funding from the eXtension Foundation
# === LICENSE:
#
# see LICENSE file

class WikiImage < ActiveRecord::Base
  self.establish_connection :imagequest
  self.table_name= 'wiki_image_list'
	self.primary_key = 'id'


  attr_accessor :desc, :copy

  def parse
    parts = self.page_text.split(/^==\s+[\w\s]*\s+==\n/)
    if(parts[1].nil?)
      self.desc = self.page_text.gsub(/\[\[Category:.*?\]\]/i,'')
    else
      d = parts[1]
      c = parts[2]
      c += parts[3] if(!parts[3].nil?)
      self.desc = d.gsub(/\[\[Category:.*?\]\]/i,'') if !d.nil?
      self.copy = c.gsub(/\[\[Category:.*?\]\]/i,'') if !c.nil?
    end
  end

  def description
    if(!self.desc)
      self.parse
    end
    self.desc
  end

  def copyright
    if(!self.copy)
      self.parse
    end
    self.copy
  end


  def self.make_image_data
    self.all.each do |wi|
      ImageData.create(filename: wi.filename, path: wi.path, source_id: wi.page_id, source: 'copwiki', description: wi.description, copyright: wi.copyright)
    end
  end

end
