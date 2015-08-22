# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
require 'net/https'

class Link < ActiveRecord::Base
  serialize :last_check_information
  include Rails.application.routes.url_helpers # so that we can generate URLs out of the model

  belongs_to :page
  has_many :linkings
  has_one :image_data_link
  has_one :image_data, :through => :image_data_link

  validates_presence_of :fingerprint, :linktype

  # this is the association for items that link to this item
  has_many :linkedpages, :through => :linkings, :source => :page

  # link types
  WANTED = 1
  INTERNAL = 2
  EXTERNAL = 3
  MAILTO = 4
  CATEGORY = 5
  DIRECTFILE = 6
  LOCAL = 7
  IMAGE = 8



  # status codes
  OK = 1
  OK_REDIRECT = 2
  WARNING = 3
  BROKEN = 4
  IGNORED = 5

  # maximum number of times a broken link reports broken before warning goes to error
  MAX_WARNING_COUNT = 3

  # maximum number of times we'll check a broken link before giving up
  MAX_ERROR_COUNT = 10

  scope :checklist, -> {where("linktype IN (#{EXTERNAL},#{LOCAL},#{IMAGE})")}
  scope :external, -> {where(:linktype => EXTERNAL)}
  scope :internal, -> {where(:linktype => INTERNAL)}
  scope :unpublished, -> {where(:linktype => WANTED)}
  scope :local, -> {where(:linktype => LOCAL)}
  scope :file, -> {where(:linktype => DIRECTFILE)}
  scope :category, -> {where(:linktype => CATEGORY)}
  scope :image, -> {where(:linktype => IMAGE)}
  scope :unlinked_images, -> { image.includes(:image_data).where('image_data.id' => nil) }

  scope :checked, -> {where("last_check_at IS NOT NULL")}
  scope :unchecked, -> {where("last_check_at IS NULL")}
  scope :good, -> {where(:status => OK)}
  scope :broken, -> {where(:status => BROKEN)}
  scope :warning, -> {where(:status => WARNING)}
  scope :redirected, -> {where(:status => OK_REDIRECT)}

  scope :checked_yesterday_or_earlier, -> {where("DATE(last_check_at) <= ?",Date.yesterday)}
  scope :checked_over_one_month_ago, -> {where("DATE(last_check_at) <= DATE_SUB(?,INTERVAL 1 MONTH)",Date.yesterday)}

  def self.is_create?(host)
    (host == 'create.extension.org' or host == 'create.demo.extension.org')
  end

  def self.is_copwiki?(host)
    (host == 'cop.extension.org' or host == 'cop.demo.extension.org')
  end

  def self.is_www?(host)
    (host == 'www.extension.org' or host == 'www.demo.extension.org')
  end

  def is_create?
    self.class.is_create?(self.host)
  end

  def is_copwiki?
    self.class.is_copwiki?(self.host)
  end

  def is_copwiki_or_create?
    self.class.is_create?(self.host) or self.class.is_copwiki?(self.host)
  end

  # note to the future humorless, the www site is currently (as of this commit)
  # the extension.org site that "has no name" (and multiple
  # attempts in the staff to attempt to give it a name) - so in an effort to
  # encapsulate something that needs to resolve to "www" - I called it
  # voldemort.  <jayoung>
  def self.is_voldemort?(host)
    self.is_create?(host) or self.is_copwiki?(host) or self.is_www?(host)
  end




  def status_to_s
    if(self.status.blank?)
      return 'Not yet checked'
    end

    case self.status
    when OK
      return 'OK'
    when OK_REDIRECT
      return 'Redirect'
    when WARNING
      return 'Warning'
    when BROKEN
      return 'Broken'
    when IGNORED
      return 'Ignored'
    else
      return 'Unknown'
    end
  end

  def href_url
    default_url_options[:host] = Settings.urlwriter_host
    default_url_options[:protocol] = Settings.urlwriter_protocol
    if(default_port = Settings.urlwriter_port)
     default_url_options[:port] = default_port
    end

    case self.linktype
    when WANTED
      return ''
    when INTERNAL
      self.page.href_url
    when EXTERNAL
      self.url
    when LOCAL
      self.url
    when MAILTO
      self.url
    when CATEGORY
      if(self.path =~ /^\/wiki\/Category\:(.+)/)
        content_tag = $1.gsub(/_/, ' ')
        category_tag_index_url(:content_tag => Tag.url_display_name(content_tag))
      elsif(self.is_create? and self.path =~ %r{^/taxonomy/term/(\d+)})
        # special case for Create taxonomy terms
        if(taxonomy_term = CreateTaxonomyTerm.find($1))
          category_tag_index_url(:content_tag => Tag.url_display_name(taxonomy_term.name))
        else
          ''
        end
      else
        ''
      end
    when DIRECTFILE
      self.path
    when IMAGE
      if(self.is_copwiki_or_create?)
        "https://www.extension.org#{self.path}"
      else
        self.url
      end
    end
  end

  def change_to_wanted
    if(self.linktype == INTERNAL)
      self.update_attribute(:linktype,WANTED)
      self.linkedpages.each do |linked_page|
        linked_page.store_content # parses links and images again and saves it.
      end
    end
  end

  def change_alternate_url
    if(self.page.alternate_source_url != self.page.source_url)
      begin
        alternate_source_uri = URI.parse(page.alternate_source_url)
        alternate_source_uri_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(alternate_source_uri.to_s.downcase))
      rescue
        # do nothing
      end
    end

    if(alternate_source_uri)
      self.alternate_url = alternate_source_uri.to_s
      self.alternate_fingerprint = alternate_source_uri_fingerprint
      self.save
    end
  end

  def self.create_from_page(page)
    if(page.source_url.blank?)
      return nil
    end

    # make sure the URL is valid format
    begin
      source_uri = URI.parse(page.source_url)
      source_uri_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(source_uri.to_s.downcase))
    rescue
      return nil
    end

    # special case for where the alternate != source_url
    if(page.alternate_source_url != page.source_url)
      begin
        alternate_source_uri = URI.parse(page.alternate_source_url)
        alternate_source_uri_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(alternate_source_uri.to_s.downcase))
      rescue
        # do nothing
      end
    end

    # specical case for create urls - does this have an alias_uri?
    if(page.page_source and page.page_source.name == 'create')
      if(!page.old_source_url.blank?)
        begin
          old_source_uri = URI.parse(page.old_source_url)
          old_source_uri_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(old_source_uri.to_s.downcase))
        rescue
          # do nothing
        end
      elsif(migrated_url = MigratedUrl.find_by_target_url_fingerprint(source_uri_fingerprint))
        old_source_uri = migrated_url.alias_url
        old_source_uri_fingerprint = migrated_url = migrated_url.alias_url_fingerprint
      end
    end

    find_condition = "fingerprint = '#{source_uri_fingerprint}'"
    if(alternate_source_uri)
      find_condition += " OR alternate_fingerprint = '#{alternate_source_uri_fingerprint}'"
    end
    if(old_source_uri)
      find_condition += " OR alias_fingerprint = '#{old_source_uri_fingerprint}'"
    end


    if(this_link = self.where(find_condition).first)
      # this was a wanted link - we need to update the link now - and kick off the process of updating everything
      # that links to this page
      this_link.update_attributes(:page => page, :linktype => INTERNAL)
      this_link.linkedpages.each do |linked_page|
        linked_page.store_content # parses links and images again and saves it.
      end
    else
      this_link = self.new(:page => page, :url => source_uri.to_s, :fingerprint => source_uri_fingerprint)

      if(alternate_source_uri)
        this_link.alternate_url = alternate_source_uri.to_s
        this_link.alternate_fingerprint = alternate_source_uri_fingerprint
      end

      if(old_source_uri)
        this_link.alias_url = old_source_uri.to_s
        this_link.alias_fingerprint = old_source_uri_fingerprint
      end

      this_link.source_host = source_uri.host
      this_link.linktype = INTERNAL

      # set host and path - mainly just for aggregation purposes
      if(!source_uri.host.blank?)
        this_link.host = source_uri.host
      end
      if(!source_uri.path.blank?)
        this_link.path = CGI.unescape(source_uri.path)
      end
      this_link.save
    end
    return this_link

    return returnlink
  end

  # this is meant to be called when parsing a piece of content for items it links out to from its content.
  def self.find_or_create_by_linked_url(linked_url,source_host)
    # make sure the URL is valid format
    begin
      original_uri = URI.parse(linked_url)
    rescue
      return nil
    end

    # is this a /wiki/Image:blah or /wiki/File:blah link? - then return nothing - it's ignored
    if(original_uri.path =~ /^\/wiki\/File:.*/ or original_uri.path =~ /^\/wiki\/Image:(.*)/)
      return ''
    end

    # explicitly ignore callto: links
    if(original_uri.scheme.blank?)
      original_uri.scheme = 'http'
    elsif(original_uri.class.name == 'URI::Generic')
      return nil
    end

    # is this a relative url? (no scheme/no host)- so attach the source_host and http
    # to it, to see if that matches an original URL that we have
    if(!original_uri.is_a?(URI::MailTo))
      if(original_uri.host.blank?)
        # wiki link exception inside existing create articles that we still have
        if(original_uri.path =~ %r{^/wiki/} and source_host == 'create.extension.org')
          original_uri.host = 'cop.extension.org'
        else
          original_uri.host = source_host
        end
      end
    end

    # for comparison purposes - we need to drop the fragment - the caller is going to
    # need to maintain the fragment when they get an URI back from this class.
    if(!original_uri.fragment.blank?)
      original_uri.fragment = nil
    end

    # check both the fingerprint and alternate_fingerprint and alias_fingerprint
    original_uri_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(original_uri.to_s.downcase))
    if(this_link = self.where("fingerprint = ? or alternate_fingerprint = ? or alias_fingerprint = ?",original_uri_fingerprint,original_uri_fingerprint,original_uri_fingerprint).first)
      return this_link
    end

    # create it - if host matches source_host and we want to identify this as "wanted" - then make it wanted else - call it external
    this_link = self.new(:source_host => source_host)
    # check to see if this is a migrated url
    if(self.is_copwiki?(original_uri.host) and migrated_url = MigratedUrl.find_by_alias_url_fingerprint(original_uri_fingerprint))
      begin
        target_uri = URI.parse(migrated_url.target_url)
        target_url_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(target_uri.to_s.downcase))
        this_link.url = target_uri.to_s
        this_link.fingerprint = target_url_fingerprint
        this_link.alias_url = original_uri.to_s
        this_link.alias_fingerprint = original_uri_fingerprint
        this_link.linktype = WANTED
        # set host and path - mainly just for aggregation purposes
        if(!target_uri.host.blank?)
          this_link.host = target_uri.host.downcase
        end
        if(!target_uri.path.blank?)
          this_link.path = CGI.unescape(target_uri.path)
        end
      rescue
        return nil
      end
    elsif(self.is_create?(original_uri.host) and migrated_url = MigratedUrl.find_by_target_url_fingerprint(original_uri_fingerprint))
      begin
        alias_uri = URI.parse(migrated_url.alias_url)
        alias_url_fingerprint = Digest::SHA1.hexdigest(CGI.unescape(alias_uri.to_s.downcase))
        this_link.alias_url = alias_uri.to_s
        this_link.alias_fingerprint = alias_url_fingerprint
        this_link.url = original_uri.to_s
        this_link.fingerprint = original_uri_fingerprint
        this_link.linktype = WANTED
        # set host and path - mainly just for aggregation purposes
        if(!original_uri.host.blank?)
          this_link.host = original_uri.host.downcase
        end
        if(!original_uri.path.blank?)
          this_link.path = CGI.unescape(original_uri.path)
        end
      rescue
        return nil
      end
    else
      this_link.url = original_uri.to_s
      this_link.fingerprint = original_uri_fingerprint

      if(original_uri.is_a?(URI::MailTo))
        this_link.linktype = MAILTO
      elsif(self.is_create?(source_host) and self.is_voldemort?(original_uri.host) and original_uri.path =~ %r{^/sites/default/files/.*})
        # exemption for create and directfile links
        this_link.linktype = DIRECTFILE
      elsif(self.is_create?(source_host) and original_uri.path =~ %r{^/taxonomy/term/(\d+)})
        # exemption for create and links to taxonomy terms
        this_link.linktype = CATEGORY
      elsif(original_uri.path =~ %r{^/wiki/Category:.*})
        this_link.linktype = CATEGORY
      elsif(self.is_create?(source_host) and self.is_voldemort?(original_uri.host) and original_uri.path =~ %r{^/mediawiki/.*})
        this_link.linktype = DIRECTFILE
      elsif(self.is_create?(source_host) and self.is_voldemort?(original_uri.host) and original_uri.path =~ %r{^/learninglessons/.*})
        this_link.linktype = DIRECTFILE
      elsif(original_uri.host == source_host)
        this_link.linktype = WANTED
      elsif(self.is_copwiki?(original_uri.host))
        # host is cop.extension.org, doesn't match the above and wasn't migrated, call it wanted
        this_link.linktype = WANTED
      elsif(original_uri.host.downcase == 'extension.org' or original_uri.host.downcase =~ /\.extension\.org$/)
        # host is extension
        this_link.linktype = LOCAL
      else
        this_link.linktype = EXTERNAL
      end

      # set host and path - mainly just for aggregation purposes
      if(!original_uri.host.blank?)
        this_link.host = original_uri.host.downcase
      end
      if(!original_uri.path.blank?)
        this_link.path = CGI.unescape(original_uri.path)
      end
    end

    this_link.save
    return this_link
  end

  # this is meant to be called when parsing a piece of content for items it links out to from its content.
  def self.find_or_create_by_image_reference(image_reference,source_host)
    # make sure the URL is valid format
    begin
      original_uri = URI.parse(image_reference)
    rescue
      return nil
    end

    if(original_uri.scheme == 'data')
      return nil
    end


    if(original_uri.host.blank?)
      # wiki link exception inside existing create articles that we still have
      if(original_uri.path =~ %r{^/mediawiki/} and source_host == 'create.extension.org')
        original_uri.host = 'cop.extension.org'
      else
        original_uri.host = source_host
      end
    end
    original_uri.scheme = 'http' if(original_uri.scheme.blank?)

    # for comparison purposes - we need to drop the fragment - the caller is going to
    # need to maintain the fragment when they get an URI back from this class.
    if(!original_uri.fragment.blank?)
      original_uri.fragment = nil
    end

    if(this_link = self.find_by_fingerprint(Digest::SHA1.hexdigest(CGI.unescape(original_uri.to_s))))
      if(this_link.linktype != IMAGE)
        this_link.update_attribute(:linktype, IMAGE)
      end
      return this_link
    end

    this_link = self.new(:url => original_uri.to_s,
                            :fingerprint => Digest::SHA1.hexdigest(CGI.unescape(original_uri.to_s)),
                            :source_host => source_host,
                            :linktype => IMAGE)

    # set host and path - mainly just for aggregation purposes
    if(!original_uri.host.blank?)
      this_link.host = original_uri.host.downcase
    end
    if(!original_uri.path.blank?)
      this_link.path = CGI.unescape(original_uri.path)
    end
    this_link.save
    return this_link
  end


  def check_url(options = {})
    save = (!options[:save].nil? ? options[:save] : true)
    force_error_check = (!options[:force_error_check].nil? ? options[:force_error_check] : false)
    make_get_request = (!options[:make_get_request].nil? ? options[:make_get_request] : false)
    check_again_with_get = (!options[:check_again_with_get].nil? ? options[:check_again_with_get] : true)

    return if(!force_error_check and self.error_count >= MAX_ERROR_COUNT)

    self.last_check_at = Time.zone.now
    result = self.class.check_url(self.url,make_get_request)
    # make get request if responded, and response code was '404' and we didn't initially make a get request
    if(result[:responded] and !make_get_request and check_again_with_get and (result[:code] =='404' or result[:code] =='405' or result[:code] =='403'))
      result = self.class.check_url(self.url,true)
    end

    if(result[:responded])
      self.last_check_response = true
      self.last_check_information = {:response_headers => result[:response].to_hash}
      self.last_check_code = result[:code]
      if(result[:code] == '200')
        self.status = OK
        self.last_check_status = OK
        self.error_count = 0
      elsif(result[:code] == '301' or result[:code] == '302' or result[:code] == '303' or result[:code] == '307')
        self.status = OK_REDIRECT
        self.last_check_status = OK_REDIRECT
        self.error_count = 0
      else
        self.error_count += 1
        if(self.error_count >= MAX_WARNING_COUNT)
          self.status = BROKEN
        else
          self.status = WARNING
        end
        self.last_check_status = BROKEN
      end
    elsif(result[:ignored])
      self.last_check_response = false
      self.status = IGNORED
      self.last_check_status = IGNORED
    else
      self.last_check_response = false
      self.last_check_information = {:error => result[:error]}
      self.error_count += 1
      if(self.error_count >= MAX_WARNING_COUNT)
        self.status = BROKEN
      else
        self.status = WARNING
      end
      self.last_check_status = BROKEN
    end
    self.save
    return result
  end

  def reset_status
    self.update_attributes(:status => nil, :error_count => 0, :last_check_at => nil, :last_check_status => nil, :last_check_response => nil, :last_check_code => nil, :last_check_information => nil)
  end


  def self.check_url(url,make_get_request=false)
    headers = {'User-Agent' => 'extension.org link verification'}
    # the URL should have likely already be validated, but let's do it again for good measure
    begin
      check_uri = URI.parse("#{url}")
    rescue Exception => exception
      return {:responded => false, :error => exception.message}
    end

    if(check_uri.scheme != 'http' and check_uri.scheme != 'https')
      return {:responded => false, :ignored => true}
    end

    # check it!
    begin
      response = nil
      http_connection = Net::HTTP.new(check_uri.host, check_uri.port)
      if(check_uri.scheme == 'https')
        # don't verify cert?
        http_connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http_connection.use_ssl = true
      end
      request_path = !check_uri.path.blank? ? check_uri.path : "/"
      if(!check_uri.query.blank?)
        request_path += "?" + check_uri.query
      end

      if(!make_get_request)
        response = http_connection.head(request_path,headers)
      else
        response = http_connection.get(request_path,headers)
      end
      {:responded => true, :code => response.code, :response => response}
    rescue Exception => exception
      return {:responded => false, :error => exception.message}
    end
  end

  def self.linktype_to_description(linktype)
    case linktype
    when WANTED
      'wanted'
    when INTERNAL
      'internal'
    when EXTERNAL
      'external'
    when MAILTO
      'mailto'
    when CATEGORY
      'category'
    when DIRECTFILE
      'directfile'
    when LOCAL
      'local'
    when IMAGE
      'image'
    else
      'unknown'
    end
  end

  def self.count_by_linktype
    returnhash = {}
    linkcounts = Link.count(:group => :linktype)
    linkcounts.each do |linktype,count|
      returnhash[self.linktype_to_description(linktype)] = count
    end
    returnhash
  end

  def connect_to_image_data
    if(%r{^/mediawiki/files/thumb} =~ self.path)
      matchpath = self.path.gsub(%r{^/mediawiki/files/thumb},'')
      ImageData.link_by_path(matchpath,self.id,'copwiki')
    elsif(%r{^/mediawiki/files} =~ self.path)
      matchpath = self.path.gsub(%r{^/mediawiki/files},'')
      ImageData.link_by_path(matchpath,self.id,'copwiki')
    elsif(%r{^/sites/default/files/w/thumb} =~ self.path)
      matchpath = self.path.gsub(%r{^/sites/default/files/w/thumb},'')
      ImageData.link_by_path(matchpath,self.id,'copwiki')
    elsif(%r{^/sites/default/files/w} =~ self.path)
      matchpath = self.path.gsub(%r{^/sites/default/files/w},'')
      ImageData.link_by_path(matchpath,self.id,'copwiki')
    elsif(%r{^/sites/default/files/styles/\w+/public/}  =~ self.path)
      matchpath = self.path.gsub(%r{^/sites/default/files/styles/\w+/public/},'')
      ImageData.link_by_path(matchpath,self.id,'create')
    elsif(%r{^/sites/default/files/} =~ self.path)
      matchpath = self.path.gsub(%r{^/sites/default/files/},'')
      ImageData.link_by_path(matchpath,self.id,'create')
    else
      # nothing for now
    end
  end

  def self.connect_unlinked_images
    self.unlinked_images.each do |image_link|
      image_link.connect_to_image_data
    end
  end


end
