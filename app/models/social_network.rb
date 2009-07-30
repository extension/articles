# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'uri'

class SocialNetwork < ActiveRecord::Base
  belongs_to :user
  attr_accessor :fieldid
  
  validates_presence_of :network, :accountid
  before_save  :check_accounturl, :check_networkname
  validates_length_of :network, :maximum=>96
  validates_length_of :accountid, :maximum=>96
  
  # known services
  
  NETWORKS = {
    'google' => {:displayname => 'Google', :editableurl => false, :autocomplete => false},
    'twitter' => {:displayname => 'Twitter', :urlformat => 'http://twitter.com/%s', :editableurl => false, :autocomplete => true},
    'friendfeed' => {:displayname => 'FriendFeed', :urlformat => 'http://friendfeed.com/%s', :editableurl => false, :autocomplete => true},
    'flickr' => {:displayname => 'Flickr', :urlformat => 'http://flickr.com/photos/%s', :editableurl => true, :autocomplete => true, :urlformatnotice => 'Your URL will not include your account name unless you have customized the settings in your Flickr account. Please confirm the link to your page.'},
    'facebook' => {:displayname => 'Facebook', :editableurl => true, :autocomplete => false},
    'magnolia' => {:displayname => 'Ma.gnolia', :urlformat => 'http://ma.gnolia.com/people/%s', :editableurl => false, :autocomplete => true},
    'delicious' => {:displayname => 'Delicious', :urlformat => 'http://delicious.com/%s', :editableurl => false, :autocomplete => true},
    'linkedin' => {:displayname => 'LinkedIn', :urlformat => 'http://www.linkedin.com/in/%s', :editableurl => true, :autocomplete => true, :urlformatnotice => '<span>http://www.linkedin.com/in/<strong>your-name</strong></span>You will need to create a custom LinkedIn Public Profile URL for the automatic linking to work.'},
    'slideshare' => {:displayname => 'SlideShare', :urlformat => 'http://slideshare.net/%s', :editableurl => false, :autocomplete => true},
    'youtube' => {:displayname => 'YouTube', :urlformat => 'http://www.youtube.com/user/%s', :editableurl => false, :autocomplete => true},
    'identica' => {:displayname => 'Identi.ca', :urlformat => 'http://identi.ca/%s', :editableurl => false, :autocomplete => true},
    'aim' => {:displayname => 'AOL Instant Messenger', :urlformat => 'aim:goim?%s', :editableurl => false, :autocomplete => true},
    'msnim' => {:displayname => 'MSN Instant Messenger', :editableurl => false, :autocomplete => true},
    'yahooim' => {:displayname => 'Yahoo Instant Messenger', :urlformat => 'ymsgr:sendim?%s', :editableurl => false, :autocomplete => true},
    'gtalk' => {:displayname => 'Google Talk', :urlformat => 'xmpp:%s', :editableurl => false, :autocomplete => true},
    'jabber' => {:displayname => 'Jabber/XMPP', :urlformat => 'xmpp:%s', :editableurl => false, :autocomplete => true}, 
    'skype' => {:displayname => 'Skype', :urlformat => 'skype:%s', :editableurl => false, :autocomplete => true},
    'blog' => {:displayname => 'Blog/Website', :editableurl => true, :autocomplete => false},
    'secondlife' => {:displayname => 'Second Life', :editableurl => false, :autocomplete => false}
  }
  
  named_scope :showpublicly, :conditions => {:is_public => 1}
  

  def check_accounturl
    if(self.accounturl == 'accounturl')
      self.accounturl = ''
    elsif !self.has_editable_url?
      # force
      self.accounturl = self.class.get_network_url(self.network, self.accountid)
    end
    return true
  end
  
  def check_networkname
    if(self.network == 'other')
      if(self.displayname.blank?)
        return false
      else
        self.network = self.displayname.downcase.gsub(/[^a-z0-9:_-]/,'')
        return true
      end
    else
      return true
    end
  end

  
  def has_editable_url?
    if(!NETWORKS.keys.include?(self.network))
      value = true
    elsif
      value = NETWORKS[self.network][:editableurl]
    end
    return value
  end
  
  def autocomplete?
    if(!NETWORKS.keys.include?(self.network))
      value = false
    elsif
      value = NETWORKS[self.network][:autocomplete].nil? ? false : NETWORKS[self.network][:autocomplete]
    end
    return value
  end

		
	  # -----------------------------------
    # Class-level methods
    # -----------------------------------
    class << self

      def per_page
        25
      end

      # returns an ordered array of network,displayname,count for the social networks in the database
      #
      # ==== Attributes
      #
      # * +includeall+ - true/false (default = true) Include an "all" networks with count
      #
      # ==== Examples
      #
      def get_networks(includeall = true,groupothers=true)
        findsql = "SELECT #{table_name}.*, COUNT(#{table_name}.`id`) as count FROM #{table_name},#{User.table_name}"
        findsql += " WHERE #{table_name}.`user_id` = #{User.table_name}.`id`"
        findsql += " AND #{User.table_name}.`retired` = 0 AND #{User.table_name}.`vouched` = 1"
        findsql += " GROUP BY #{table_name}.`network`"
        networkslist = find_by_sql(findsql)
        if(networkslist.nil?)
          return []
        else
          
          dbnetworks = []
          othernetworksum = 0
          networkslist.map do |social_network|
            if(SocialNetwork::NETWORKS.keys.include?(social_network.network))
              known_network = true
              displayname = SocialNetwork::NETWORKS[social_network.network][:displayname]
            else
              known_network = false
              displayname = social_network.displayname
              othernetworksum = othernetworksum + social_network.count.to_i
            end
            
            if(known_network or !groupothers)
              dbnetworks << [social_network.network,displayname,social_network.count]
            end
              
          end
          
          if(includeall)
            returnnetworks = [['all','All Networks',SocialNetwork.count(:all)]]
            dbnetworks.sort.each do |item|
              returnnetworks << item
            end
          else
            returnnetworks = dbnetworks.sort
          end
          
          if(groupothers)
            returnnetworks << ['other','Other Networks',othernetworksum]
          end
          
          return returnnetworks
        end
      end
      
      def get_edit_networks(includeother = true)
        return_networks = []
        SocialNetwork::NETWORKS.keys.sort.each do |network|
          return_networks << [network,SocialNetwork::NETWORKS[network][:displayname]]
        end
        if(includeother)
          return_networks << ['other','Other Network']
        end
        return return_networks
      end
      
      
      def get_name(network)
        SocialNetwork::NETWORKS.keys.include?(network) ? SocialNetwork::NETWORKS[network][:displayname] : "Other Network (#{network.upcase})"
      end
      
      def get_network_url(network,accountid)
        network_url = '' # default
        if(SocialNetwork::NETWORKS.keys.include?(network))
          urlformat = SocialNetwork::NETWORKS[network][:urlformat]
          if(!urlformat.nil?)
            network_url = sprintf(urlformat,accountid)
          end
        end
        return network_url
      end
      
      def has_editable_url?(network)
        if(!NETWORKS.keys.include?(network))
          return true
        elsif
          value = NETWORKS[network][:editableurl]
          return value
        end
      end
      
      def get_filter_condition(networknames)
        if(networknames.is_a?(Array))
          return "social_networks.network IN (#{networknames.map{|network| "'#{network}'"}.join(',')})"
        elsif(networknames.is_a?(String))
          if(networknames == 'all')
            return nil
          elsif(networknames == 'other')
            known_list = SocialNetwork::NETWORKS.keys.sort.map{|network| "'#{network}'"}.join(",")
            return "social_networks.network NOT IN (#{known_list})"
          else
            return "social_networks.network = '#{networknames}'"
          end
        else
          return nil
        end
      end
      
  	end  # class methods
end