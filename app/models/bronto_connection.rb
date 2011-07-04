# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class BrontoConnection
  
  JITP_DELIVERY_GROUP = '54e33a5a-145c-4791-8ceb-55f803749335'
  
  
  attr_accessor :v3_session_id, :v3_client_connection
  attr_accessor :session_id, :client_connection
  
  
  def initialize(savon_logging = false)
    Savon.configure do |config|
      config.log = savon_logging
    end
    
    self.v3_client_connection = Savon::Client.new do 
      wsdl.document = "http://api.bronto.com/?q=mail_3&wsdl" 
    end

    self.client_connection = Savon::Client.new do 
      wsdl.document = "https://api.bronto.com/v4?wsdl" 
    end
  end
  
  def connect
    self.connect_v3
    self.connect_v4
    {:v3 => self.v3_session_id, :v4 => self.session_id}
  end
  
  def connect_v3
    begin
      response =  self.v3_client_connection.request(:v3, :login) do
        soap.body = {
          :username => AppConfig.configtable['bronto_username'],
          :password => AppConfig.configtable['bronto_password'],
          :sitename => AppConfig.configtable['bronto_sitename']
        }
      end
  
      if(response)
        self.v3_session_id = response.to_hash[:login_response][:return][:session_id]
      end
      response
    rescue
      return nil
    end
  end
    
  def connect_v4
    begin
      response =  self.client_connection.request(:v4, :login) do
        soap.body = {
          :api_token => AppConfig.configtable['bronto_api_key']
        }
      end
  
      if(response)
        self.session_id = response.to_hash[:login_response][:return]
      end
      response
    rescue
      return nil
    end
  end
  
  
  def read_click_activities_after(activity_date = Date.yesterday)  
    if(!self.session_id)
      self.connect
    end
    
    response = self.client_connection.request(:v4, :read_activities) do
      soap.header = { 
        "v4:sessionHeader" => {
          :session_id => self.session_id 
        }
      }
    
      soap.body = {
        :filter => {
          :start => activity_date,
          :size => 5000,  # completely arbitrary value that will hopefully get everything
          :types => ['click']
        }
      }
    end
    
    results = response.to_hash[:read_activities_response][:return]
    results
  end
  
  def read_sent_deliveries_on(delivery_date = Date.yesterday)
  
    if(!self.session_id)
      self.connect
    end
    results = []
    
    filter = {
      :start => {
        :operator => 'SameDay',
        :value => delivery_date
      },
      :status => 'sent',
    }
  
    page_number = 1
    begin 
      response = self.client_connection.request(:v4, :read_deliveries) do
        soap.header = { 
          "v4:sessionHeader" => {
            :session_id => self.session_id 
          }
        }
        soap.body = {
          :filter => filter,
          # :include_recipients => true,
          :page_number => page_number,
        }
      end
      
      response_return = response[:read_deliveries_response][:return]
      if(response_return)
        results += response_return
        page_number += 1  
      end
    end while not response_return.blank?
    results
  end
  
  
  # gets the sends for a particular delivery
  # this is a v3 api call because as of implementation
  # the v4 equivalent (readActivities, sends) has a bug
  # (according to Bronto) that is causing it to return
  # an error the sends value is included in the readActivities
  # call
  def read_sends_for_delivery(delivery_id)
    
    if(!self.v3_session_id)
      self.connect
    end
    results = []
    
    filter = {
      :value => {
        :type => 'string',
        :value => delivery_id
      },
      :attribute => 'deliveryId',
      :comparison => '=',
    }    
  
    response = self.v3_client_connection.request(:api, :read_sends) do
      soap.header = { 
        "api:sessionHeader" => {
          'api:sessionId' => self.v3_session_id 
        }
      }
      soap.body = {
        :filter => {:criteria => filter},
        :attributes => {:created => true}
      }
    end
    
    if(response[:read_sends_response][:return] and response[:read_sends_response][:return][:sends])
      return_response = response[:read_sends_response][:return][:sends]
      if(return_response.is_a?(Array))
        results += return_response
      else
        results << return_response
        return results
      end
    else
      return results
    end
    
    begin
      next_response = self.v3_client_connection.request(:api, :read_next) do
        soap.header = { 
          "api:sessionHeader" => {
            'api:sessionId' => self.v3_session_id 
          }
        }
      end
      if(next_response[:read_next_response][:return] and next_response[:read_next_response][:return][:sends])
        next_response_return = next_response[:read_next_response][:return][:sends]
      else
        next_response_return = nil
      end
      if(next_response_return)
        if(next_response_return.is_a?(array))
          results += next_response_return
        else
          results << next_response_return
        end
      end
    end while not next_response_return.blank?
    results
  end
  

  def read_messages_for_delivery_group_id(delivery_group_id)
    if(!self.session_id)
      self.connect
    end
    
    filter = {
      :delivery_group_id => delivery_group_id,
      :list_by_type => 'MESSAGEGROUPS'
    }
  
    response = self.client_connection.request(:v4, :read_delivery_groups) do
      soap.header = { 
        "v4:sessionHeader" => {
          :session_id => self.session_id 
        }
      }
      soap.body = {
        :filter => filter,
      }
    end
    
    results = response[:read_delivery_groups_response][:return][:message_ids]
    results
  end
  
  def read_message_for_id(message_id)
    if(!self.session_id)
      self.connect
    end
    
    filter = {
      :id => message_id,
    }
  
    response = self.client_connection.request(:v4, :read_messages) do
      soap.header = { 
        "v4:sessionHeader" => {
          :session_id => self.session_id 
        }
      }
      soap.body = {
        :filter => filter,
      }
    end
    
    results = response[:read_messages_response][:return]
    results
  end
  
  def read_contact_for_id(contact_id)
    if(!self.session_id)
      self.connect
    end
    
    filter = {
      :id => contact_id,
    }
  
    response = self.client_connection.request(:v4, :read_contacts) do
      soap.header = { 
        "v4:sessionHeader" => {
          :session_id => self.session_id 
        }
      }
      soap.body = {
        :filter => filter,
      }
    end
    
    results = response[:read_contacts_response][:return]
    results
  end  
    

end