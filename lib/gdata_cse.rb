# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'gdata'

module GData
  module Client
    
    # Client class to wrap working with the Google Custom Search Engine API.
    # http://code.google.com/intl/en/apis/customsearch/docs/api.html
    class Cse < Base
      
      attr_accessor :urls
      attr_accessor :cse_id
      
      def initialize(options = {})
        @urls = Array.new
        @cse_id = nil
        
        options[:clientlogin_service] ||= 'cprose'
        options[:source] ||= 'darmok' # our AppName
        options[:authsub_scope] ||= 'http://www.google.com/cse/api/default/cse/'
        
        super(options)
      end
      
      def clientlogin(username, password, captcha_token = nil, 
        captcha_answer = nil, service = nil, account_type = nil)
        returndata = super(username, password)
        
        begin
          self.setup
          returndata
        rescue StandardError => e
          nil
        end
        
      end
      
      def setup
        returndata = false
        cseList = 'https://www.google.com/cse/api/default/cse/'
        cseXML = self.get(cseList).to_xml
        idList = cseXML.elements.each('//@id') # get matching attr list
        
        if idList and idList.length > 0
          @cse_id = "_cse_" + idList[0].value
          returndata = true
        end
        
        return returndata
      end
      
      def getAnnotations(options={})
        allAnnotations = 'http://www.google.com/cse/api/default/annotations/'
        if options.include?(:start)
          allAnnotations << "?start=#{options[:start]}"
        end
        response = self.get(allAnnotations)
        return self.updateLocal(response, options)
      end
      
      def setAnnotations(xml, options={})
        response = self.post("http://www.google.com/cse/api/default/annotations/", xml)
        return self.parseResponse(response)
      end
      
      def addAnnotation(urls, options={})
        xml = ""
        # generate XML for add
        xml << "<Batch>"
        xml << "<Add>"
        xml << "<Annotations>"
        urls.each do |url|
          xml << "<Annotation about=\"#{url}\">"
          xml << "<Label name=\"#{@cse_id}\"/>"
          xml << "</Annotation>"
        end
        xml << "</Annotations>"
        xml << "</Add>"
        xml << "</Batch>"
        # do add
        return self.setAnnotations(xml,options)
      end
      
      def removeAnnotation(refs, options={})
        xml = ""
        # generate XML for remove
        xml << "<Batch>"
        xml << "<Remove>"
        xml << "<Annotations>"
        refs.each do |ref|
          xml << "<Annotation href=\"#{ref}\"/>"
        end
        xml << "</Annotations>"
        xml << "</Remove>"
        xml << "</Batch>"
        # do remove
        return self.setAnnotations(xml,options)
      end
      
      def updateLocal(response, options={})
        returndata = nil
        if response.status_code == 200
          xmldoc = response.to_xml
          
          if xmldoc
            xmldoc.elements.each('/Annotations/Annotation/') do |element|
              @urls << {:href => element.attributes['href'],
                           :url => element.attributes['about'],
                           :added_at => element.attributes['timestamp']}
            end
            
            begin
              # <Annotations total='1101' start='0' num='20'> ... </>
              num = xmldoc.elements['/Annotations'].attributes['num'].to_i
              start = xmldoc.elements['/Annotations'].attributes['start'].to_i
            rescue
              num = nil
              start = nil
            end
            
            # if we have a num value, then we are getting the whole list
            # if num is 20, then there could be more to get
            # we set the next start value at the current + 20 more
            if num and num == 20
              start += 20
              options[:start] = start
              self.getAnnotations(options)
            end
            
            returndata = @urls
          end
        else
          # either got a 201 or 302, neither are defined for CSE
          raise UnknownError.new(response)
        end
        
        return returndata
      end
      
      def parseResponse(response, options={})
        returndata = Array.new
        
        # 200 for adds, 204 for removes
        if [200, 204].include?(response.status_code)
           
          xmldoc = response.to_xml
          
          if xmldoc
            xmldoc.elements.each('/Batch/Add/Annotations/Annotation/') do |element|
              returndata << {:href => element.attributes['href'],
                           :url => element.attributes['about'],
                           :added_at => element.attributes['timestamp']}
            end
            
            xmldoc.elements.each('/Batch/Remove/Annotations/Annotation/') do |element|
              returndata << element.attributes['href']
            end
          end #xmldoc
        end #valid response
        
        return returndata
      end
      
    end #class Cse
  end #module Client
end #module GData