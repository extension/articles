# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module GData
  module Client
    
    # Client class to wrap working with the Documents List Data API.
    class Cse < Base
      
      attr_accessor :domains
      attr_accessor :cse_id
      
      def initialize(options = {})
        @domains = Hash.new
        @cse_id = nil
        
        options[:clientlogin_service] ||= 'cprose'
        options[:authsub_scope] ||= 'http://www.google.com/cse/api/default/cse/'
        super(options)
      end
      
      def clientlogin(username, password, captcha_token = nil, 
        captcha_answer = nil, service = nil, account_type = nil)
        returndata = super(username, password)
        if ! self.setup
          returndata = nil
        end
        return returndata
      end
      
      def setup
        returndata = false
        cseList = 'http://www.google.com/cse/api/default/cse/'
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
        response = self.get(allAnnotations)
        return self.updateLocal(response)
      end
      
      def setAnnotations(xml, options={})
        response = self.post("http://www.google.com/cse/api/default/annotations/", xml)
        return self.updateLocal(response)
      end
      
      def addAnnotations(domains, options={})
        xml = ""
        # generate XML for add
        xml << "<Batch>"
        xml << "<Add>"
        xml << "<Annotations>"
        domains.each do |dom|
          xml << "<Annotation about=\"#{dom}\">"
          xml << "<Label name=\"#{@cse_id}\"/>"
          xml << "</Annotation>"
        end
        xml << "</Annotations>"
        xml << "</Add>"
        xml << "</Batch>"
        # do add
        return self.setAnnotations(xml,options)
      end
      
      def removeAnnotations(refs, options={})
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
      
      def updateLocal(response)
        returndata = nil
        if response.status_code == 200
          begin
            xmldoc = response.to_xml
            
            xmldoc.elements.each('Annotations/Annotation') do |element|
              p "bulk add #{annote}"
              @domains[element.attributes['href']] = element.attributes['about']
            end
            
            xmldoc.elements.each('Add/Annotations/Annotation') do |element|
              p "adding #{annote}"
              @domains[element.attributes['href']] = element.attributes['about']
            end
            
            xmldoc.elements.each('Remove/Annotations/Annotation') do |element|
              p "removing #{annote}"
              @domains.delete(element.attributes['href'])
            end
            returndata = @domains
          rescue
            returndata = nil
          end
        end
        return returndata
      end
      
    end #class Cse
  end #module Client
end #module GData