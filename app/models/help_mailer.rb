# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class HelpMailer < ActionMailer::Base
  
  def contact_email(contact,addinfo)
    sent_at = Time.now
    if(AppConfig.configtable['mail_label'] == 'production')
      subjectlabel = "eXtension People: "
    else
      subjectlabel = "eXtension People (#{AppConfig.configtable['mail_label']}): "
    end
  
    if(contact.typeofcontact == 'feedback')
      @subject        = subjectlabel+'(Feedback) '+contact.subject
      @recipients     = AppConfig.configtable['mail_to_feedback']
    elsif(contact.typeofcontact == 'bug')
      @subject        = subjectlabel+'(Bug Report) '+contact.subject
      @recipients     = AppConfig.configtable['mail_to_bugs']
    else
      @subject        = subjectlabel+'(Support Request) '+contact.subject
      @recipients     = AppConfig.configtable['mail_to_help']
    end      
  
    @body           = {:contact => contact, :addinfo => addinfo}
    @from           = "\"#{contact.name}\" <#{contact.email}>"
    @sent_on        = sent_at
    if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
      @bcc            = AppConfig.configtable['mail_system_bcc']
    end
    @headers        = {}
  end

end