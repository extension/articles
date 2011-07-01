# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class BrontoConnection
  
  
  attr_accessor :v3_session_id, :v3_client_connection
  attr_accessor :session_id, :client_connection
  
  
  def initialize
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
          :include_recipients => true,
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

end