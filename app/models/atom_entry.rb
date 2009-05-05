# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# @JER fix this crap
class AtomEntry
  attr_accessor :id, :title, :updated, :author, :content, :link, :summary,
    :categories, :contributors, :published, :rights
    
  def self.entries_from_xml(xml)
    entries = []
    
    document = REXML::Document.new(xml).root
    document.elements.each("//entry") do |entry|
      ae = AtomEntry.new
      ae.id = entry.elements["id"].get_text.to_s if entry.elements["id"]

      # logger.debug "Found entry with ID: " + ae.id

      next if !ae.id

      ae.title = CGI.unescapeHTML(entry.elements["title"].get_text.to_s) if entry.elements["title"]
      f = REXML::Formatters::Default.new
      
      ae.summary = ''
      if entry.elements["summary"]
        f.write(entry.elements["summary"], ae.summary)
      end
      ae.summary = strip_outer_tag(ae.summary)
      
      ae.summary = CGI.unescapeHTML(ae.summary)

      ae.content = ''
      if entry.elements["content"]
        f.write(entry.elements["content"], ae.content)
      end

      ae.content = strip_outer_tag(ae.content)
      
      ae.content = CGI.unescapeHTML(ae.content)
      if entry.elements["link"]
          ae.link = entry.elements["link"].attributes["href"]
      end

      ae.categories = []

      entry.elements.each("category") do |category|
        ae.categories << category.attributes["term"]
      end
      
      ae.updated = entry.elements["updated"].get_text.to_s if entry.elements["updated"]
      ae.published = entry.elements["published"].get_text.to_s if entry.elements["published"]
      author = AtomAuthor.new
      
      
      author.name = entry.elements["author/name"].get_text.to_s if entry.elements["author/name"]
      author.email = entry.elements["author/email"].get_text.to_s if entry.elements["author/email"]
      author.uri = entry.elements["author/uri"].get_text.to_s if entry.elements["author/uri"]

      ae.author = author
      
      entries << ae
    end
    
    entries
  end
    
  def self.strip_outer_tag(str = "")
    md = str.match(/<(\w+)\s*.*?>(.*)<\/\1>/m)

    if md
      return md[2]
    else
      return str
    end
  end
end