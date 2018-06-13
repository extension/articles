xml.instruct!
xml.rss "version" => "2.0", \
"xmlns:excerpt" => "http://wordpress.org/export/1.2/excerpt/",\
"xmlns:content" => "http://purl.org/rss/1.0/modules/content/", \
"xmlns:wfw" => "http://wellformedweb.org/CommentAPI/", \
"xmlns:dc" => "http://purl.org/dc/elements/1.1/", \
"xmlns:wp" => "http://wordpress.org/export/1.2/" do

  xml.channel do
    xml.title "eXtension Articles"
    xml.link root_url
    xml.pubDate Time.now.utc.to_s(:rfc822)
    xml.language 'en-US'
    xml.wp :wxr_version do xml.text!("1.2") end
    xml.wp :base_site_url do xml.text! root_url end
    xml.wp :base_blog_url do xml.text! root_url end
    xml.item do
      xml.wp :post_type do xml.cdata!("page") end
      xml.title @page.title
      xml.content :encoded do
        xml.cdata!(@page.content)
      end
      xml.link pageid_url(id: @page.id)
      xml.guid pageid_url(id: @page.id)
      xml.pubDate @page.source_updated_at.to_s(:rfc822)
      @page.tag_names.each do |name|
        xml.category("scheme" => root_url, "term" => name)
      end
    end
  end
end
