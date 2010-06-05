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
      
      def initialize(options = {})
        options[:clientlogin_service] ||= 'cprose'
        options[:authsub_scope] ||= 'http://www.google.com/cse/api/default/cse/'
        super(options)
      end
      
      def getAnnotations(options={})
        allAnnotations = 'http://www.google.com/cse/api/default/annotations/'
        annotations = self.get(allAnnotations).to_xml
        self.annotationsToHash(annotations)
      end
      
      def setAnnotations(xml, options={})
        response = client.post("http://www.google.com/cse/api/default/annotations/", xml)
        return self.updateLocal(response)
      end
      
      def addAnnotations(domains, options={})
        xml = ""
        # generate XML for add
        xml << "<Batch>"
        xml << "<Add>"
        xml << "<Annotations"
        domains.each do |dom|
          xml << "<Annotation about=\"#{dom}\">"
          xml << "<Label name=\"#{@cse_name}\"/>"
          xml << "</Annotation>"
        end
        xml << "</Annotations>"
        xml << "</Add>"
        xml << "</Batch>"
        # do add
        # if successful, update our copy
      end
      
      def removeAnnotations(refs, options={})
        xml = ""
        cse = @cse_name
        # generate XML for remove
        xml << "<Batch>"
        xml << "<Add>"
        xml << "<Annotations"
        <Batch>
          <Add>
            <Annotations>
              <Annotation about="http://www.solarenergy.org/*">
                <Label name="_cse_solar_example"/>
              </Annotation>
              <Annotation about="http://www.solarfacts.net/*">
                <Label name="_cse_solar_example"/>
              </Annotation>
              <Annotation about="http://en.wikipedia.org/wiki/*">
                <Label name="_cse_exclude_solar_example"/>
              </Annotation>

           </Annotations>
          </Add>
        </Batch>
        xml << "</Annotations>"
        xml << "</Add>"
        xml << "</Batch>"
        # do remove
        # if successful, update our copy
        refs.each {|r| @domains.delete(r)}
      end
      
      def self.annotationsToHash(annotes)
        @domains = Hash.new
      end
    end
  end
end