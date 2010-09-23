class CreatePostfixAliasTable < ActiveRecord::Migration
  def self.up
    
    create_table "email_aliases", :force => true do |t|
      t.integer  "user_id",    :default => 0, :null => false
      t.integer  "community_id",    :default => 0, :null => false
      t.string   "mail_alias",                     :null => false
      t.string   "destination",              :null => false
      t.integer  "alias_type", :default => 0, :null => false               
      t.integer  "created_by", :default => 1
      t.integer  "last_modified_by", :default => 1
      t.boolean  "disabled",  :default => false
      t.timestamps
    end
    
    add_index "email_aliases", ["mail_alias","destination"], :name => "alias_destination_ndx", :unique => true
    
    EmailAlias.reset_column_information
    
    # create entries for extension.org email addresses
    EmailAlias.create(:user => User.find_by_login('agriffin'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'asghorse@gmail.com')
    EmailAlias.create(:user => User.find_by_login('athundle'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'athundle@ncsu.edu')
    EmailAlias.create(:user => User.find_by_login('benmac'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'ben_macneill@ncsu.edu')
    EmailAlias.create(:user => User.find_by_login('bnr1'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'bnr1@psu.edu')
    EmailAlias.create(:user => User.find_by_login('dcotton'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'dcymore@gmail.com')
    EmailAlias.create(:user => User.find_by_login('hritchie'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'retta74@gmail.com')
    EmailAlias.create(:user => User.find_by_login('jayoung'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'jason.young@ncsu.edu')
    EmailAlias.create(:user => User.find_by_login('jerobins'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'jerobins@ncsu.edu')
    EmailAlias.create(:user => User.find_by_login('karendemo'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'kjjeannette@gmail.com')
    EmailAlias.create(:user => User.find_by_login('kjgamble'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'kevin.j.gamble@gmail.com')
    EmailAlias.create(:user => User.find_by_login('kylelkostelecky'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'kyle.kostelecky@gmail.com')
    EmailAlias.create(:user => User.find_by_login('llippke'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'larry.lippke@gmail.com')
    EmailAlias.create(:user => User.find_by_login('lspicer'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'lynette.spicer@gmail.com')
    EmailAlias.create(:user => User.find_by_login('luannphillips'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'luannsphillips@gmail.com')
    EmailAlias.create(:user => User.find_by_login('nbroady0001'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'nbroady0001@gmail.com')
    EmailAlias.create(:user => User.find_by_login('sdnall'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'sdnall@ncsu.edu')
    EmailAlias.create(:user => User.find_by_login('tmeisenbach'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'tmeisenbach@gmail.com')
    EmailAlias.create(:user => User.find_by_login('woodch'), :alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'chorse.wood@gmail.com')
    
    # special case for mr. peoplebot
    EmailAlias.create(:user => User.find_by_login('extension'), :mail_alias =>  'extension', :alias_type => EmailAlias::INDIVIDUAL_GOOGLEAPPS)
    
    # users
    execute "INSERT INTO email_aliases (user_id, mail_alias, destination, alias_type, created_at, updated_at) " + 
    "SELECT id, login, email, #{EmailAlias::INDIVIDUAL_FORWARD}, NOW(), NOW() FROM users " + 
    "WHERE users.email NOT LIKE '%extension.org%' and users.retired = 0 and users.vouched = 1"
    
    # go back and do aliases@extension.org for users
    EmailAlias.create(:mail_alias =>  'aaron.hundley', :user => User.find_by_login('athundle'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'aaron_hundley', :user => User.find_by_login('athundle'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'anne.adrian', :user => User.find_by_login('aadrian'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'ashley.griffin', :user => User.find_by_login('agriffin'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'ashley_griffin', :user => User.find_by_login('agriffin'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'ben.macneill', :user => User.find_by_login('benmac'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'beth.raney', :user => User.find_by_login('bnr1'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'carla.craycraft', :user => User.find_by_login('ccraycra'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'carla_craycraft', :user => User.find_by_login('ccraycra'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'craig.wood', :user => User.find_by_login('woodch'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'craig_wood', :user => User.find_by_login('woodch'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'dan.cotton', :user => User.find_by_login('dcotton'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'dan_cotton', :user => User.find_by_login('dcotton'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'daniel.nall', :user => User.find_by_login('sdnall'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'floyd.davenport', :user => User.find_by_login('floyd'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'henrietta.ritchie', :user => User.find_by_login('hritchie'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'henrietta_ritchie', :user => User.find_by_login('hritchie'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'masteress.of.the.universe', :user => User.find_by_login('hritchie'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'ivelin.denev', :user => User.find_by_login('idenev'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'james.robinson', :user => User.find_by_login('jerobins'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'jason.young', :user => User.find_by_login('jayoung'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'jason_young', :user => User.find_by_login('jayoung'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'karen.jeannette', :user => User.find_by_login('karenjeannette'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'kevin.gamble', :user => User.find_by_login('kjgamble'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'kevin_gamble', :user => User.find_by_login('kjgamble'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'kyle.kostelecky', :user => User.find_by_login('kylelkostelecky'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'larry.lippke', :user => User.find_by_login('llippke'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'linda.kiesel', :user => User.find_by_login('lkiesel'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'lisa.coulter', :user => User.find_by_login('llewis'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'lynette.spicer', :user => User.find_by_login('lspicer'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'luann.phillips', :user => User.find_by_login('luannphillips'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'michelle.giddens', :user => User.find_by_login('michellegiddens'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'michael.lambur', :user => User.find_by_login('mikelambur'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'mike.lambur', :user => User.find_by_login('mikelambur'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'nick.broady', :user => User.find_by_login('nbroady0001'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'ray.kimsey', :user => User.find_by_login('rkimsey'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'ray_kimsey', :user => User.find_by_login('rkimsey'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'terry.meisenbach', :user => User.find_by_login('tmeisenbach'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
    EmailAlias.create(:mail_alias =>  'terry_meisenbach', :user => User.find_by_login('tmeisenbach'), :alias_type => EmailAlias::INDIVIDUAL_ALIAS)
      
    # go back and change aadrian, karenjeannette, and lkiesel
    EmailAlias.find_by_mail_alias('aadrian').update_attributes(:alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'aafromaa@gmail.com')
    EmailAlias.find_by_mail_alias('karenjeannette').update_attributes(:alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'kjjeannette@gmail.com')
    EmailAlias.find_by_mail_alias('lkiesel').update_attributes(:alias_type => EmailAlias::INDIVIDUAL_FORWARD_CUSTOM, :destination => 'lkiesel10@gmail.com')
    
    # communities
    execute "INSERT INTO email_aliases (community_id, mail_alias, destination, alias_type, created_at, updated_at) " + 
    "SELECT id, shortname, 'noreply', #{EmailAlias::COMMUNITY_NOWHERE}, NOW(), NOW() FROM communities"
    
    
     # Other aliases

    # pseudo-accounts
    EmailAlias.create(:mail_alias =>  'aaenotify.bcc.mirror', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'aaenotify.bcc.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'aaepublic.bcc.mirror', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'aaepublic.bcc.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'abuse', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
    EmailAlias.create(:mail_alias =>  'apperrors', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'apperrors.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'apperrors', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'dev-apperrors@lists.extension.org')
    EmailAlias.create(:mail_alias =>  'clamav', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
    EmailAlias.create(:mail_alias =>  'cronmon.bcc.mirror', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'cronmon.bcc.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'default.bcc.mirror', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'default.bcc.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'deploys.mirror', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'deploys.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'exsysreport', :user => User.find_by_login('sdnall'), :alias_type => EmailAlias::SYSTEM_ALIAS)
    EmailAlias.create(:mail_alias =>  'exsysreport', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'sysreport.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'extensionapperrors', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'apperrors')
    EmailAlias.create(:mail_alias =>  'extensionbugs', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'eXtensionHelp')
    EmailAlias.create(:mail_alias =>  'extensionhelp', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'help.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'extensionhelp', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'support-notifications')
    EmailAlias.create(:mail_alias =>  'extensionwcc', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'extensionwcc@iastate.edu')
    EmailAlias.create(:mail_alias =>  'extensionwcc', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'wcc.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'feedback', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'engineering@lists.extension.org')
    EmailAlias.create(:mail_alias =>  'feedback', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'feedback.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'ftp', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
    EmailAlias.create(:mail_alias =>  'hardware', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'systemalerts')
    EmailAlias.create(:mail_alias =>  'mailer-daemon', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
    EmailAlias.create(:mail_alias =>  'mittnet.bcc.mirror', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'mittnet.bcc.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'monitoringalerts', :user => User.find_by_login('jayoung'), :alias_type => EmailAlias::SYSTEM_ALIAS)
    EmailAlias.create(:mail_alias =>  'monitoringalerts', :user => User.find_by_login('sdnall'), :alias_type => EmailAlias::SYSTEM_ALIAS)
    EmailAlias.create(:mail_alias =>  'monitoringalerts', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'monitoringalerts.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'moodlehelp', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'extensionmoodlehelp@gmail.com')
    EmailAlias.create(:mail_alias =>  'moodlehelp', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'moodlehelp.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'news', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
    EmailAlias.create(:mail_alias =>  'nobody', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
    EmailAlias.create(:mail_alias =>  'noc', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
    EmailAlias.create(:mail_alias =>  'people.bcc.mirror', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'people.bcc.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'postmaster', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
    EmailAlias.create(:mail_alias =>  'root', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'exserverroot')
    EmailAlias.create(:mail_alias =>  'support-notifications', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'support-notifications@lists.extension.org')
    EmailAlias.create(:mail_alias =>  'systemalerts', :user => User.find_by_login('jayoung'), :alias_type => EmailAlias::SYSTEM_ALIAS)
    EmailAlias.create(:mail_alias =>  'systemalerts', :user => User.find_by_login('sdnall'), :alias_type => EmailAlias::SYSTEM_ALIAS)
    EmailAlias.create(:mail_alias =>  'systemalerts', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'systemalerts.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'systemnotices', :user => User.find_by_login('jayoung'), :alias_type => EmailAlias::SYSTEM_ALIAS)
    EmailAlias.create(:mail_alias =>  'systemnotices', :user => User.find_by_login('sdnall'), :alias_type => EmailAlias::SYSTEM_ALIAS)
    EmailAlias.create(:mail_alias =>  'systemnotices', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'systemnotices.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'systems', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'systems.mirror@mail.extension.org')
    EmailAlias.create(:mail_alias =>  'usenet', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
    EmailAlias.create(:mail_alias =>  'www', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'root')
   EmailAlias.create(:mail_alias =>  'aaenotify', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'aaenotify@mail.extension.org')  
   EmailAlias.create(:mail_alias =>  'aamg', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'aamg.mirror@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'aamg', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'aamg@umn.edu')
   EmailAlias.create(:mail_alias =>  'aamg', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'extmnmg@lists.extension.org')
   EmailAlias.create(:mail_alias =>  'anonymous', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'anonymous@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'apcups-monitor', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'apcups-monitor@mail.extension.org')                        
   EmailAlias.create(:mail_alias =>  'appleRegistration', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'appleRegistration@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'ask-an-expert', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'ask-an-expert@mail.extension.org')   
   EmailAlias.create(:mail_alias =>  'certificates', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'certificates@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'copyright', :user => User.find_by_login('dcotton'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'copyright', :user => User.find_by_login('kjgamble'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'copyright', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'copyright.mirror@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'cronmon', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'cronmon@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'dcymore', :user => User.find_by_login('dcotton'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'dev-announce', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'engineering@lists.extension.org')
   EmailAlias.create(:mail_alias =>  'director', :user => User.find_by_login('dcotton'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'drupalmail', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'drupalmail@mail.extension.org')                                                    
   EmailAlias.create(:mail_alias =>  'exdev', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'exdev@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'exdev-commits', :user => User.systemuser, :alias_type =>  EmailAlias::SYSTEM_FORWARD, :destination => 'exdev@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'exdev-justcode', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'exdev@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'exlists', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'exmaillists@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'exserverroot', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'exserverroot@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'eXsys', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'eXsys@mail.extension.org')       
   EmailAlias.create(:mail_alias =>  'eXtensionAboutTeam', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'about.mirror@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'eXtensionAboutTeam', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'extension-about@lists.extension.org')     
   EmailAlias.create(:mail_alias =>  'extensionorgsys', :user => User.find_by_login('jayoung'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'extensionorgsys', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'extensionorgsys.mirror@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'googlamesh', :user => User.find_by_login('benmac'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'googlamesh', :user => User.find_by_login('jayoung'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'googlamesh', :user => User.find_by_login('jerobins'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'googlamesh', :user => User.find_by_login('kjgamble'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'googlamesh', :user => User.find_by_login('sdnall'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'hostmaster', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'hostmaster@mail.extension.org')     
   EmailAlias.create(:mail_alias =>  'information', :user => User.find_by_login('dcotton'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'information', :user => User.find_by_login('tmeisenbach'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'information', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'information.mirror@mail.extension.org')     
   EmailAlias.create(:mail_alias =>  'milfam.project.requests', :user => User.find_by_login('raouldemars'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'milfam.project.requests', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'exmail+monitor-milfam.requests@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'mittmail', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'mittmail@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'monitor', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'monitor@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'no-reply', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'no-reply@mail.extension.org')             
   EmailAlias.create(:mail_alias =>  'noreplies', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'noreplies@mail.extension.org')        
   EmailAlias.create(:mail_alias =>  'noreply', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'noreply@mail.extension.org')        
   EmailAlias.create(:mail_alias =>  'parenting', :user => User.find_by_login('aebata'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'parenting', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'parenting.mirror@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'peoplemail', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'peoplemail@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'permission', :user => User.find_by_login('woodch'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'permission', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'permissions.mirror@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'privacy', :user => User.find_by_login('dcotton'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'privacy', :user => User.find_by_login('jayoung'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'privacy', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'privacy.mirror@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'rootcertificate', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'rootcertificate@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'security', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'security@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'sourcecode-commits', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'dev-commits@lists.extension.org')     
   EmailAlias.create(:mail_alias =>  'sourcecode-commits', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'sourcecode.commits.mirror@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'spamtrap', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'spamtrap@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'swlicences', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'swlicences@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'systems-commits', :user => User.find_by_login('athundle'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'systems-commits', :user => User.find_by_login('jayoung'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'systems-commits', :user => User.find_by_login('sdnall'), :alias_type => EmailAlias::SYSTEM_ALIAS)
   EmailAlias.create(:mail_alias =>  'systems-commits', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'systems.commits.mirror@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'webmaster', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'webmaster@mail.extension.org')
   EmailAlias.create(:mail_alias =>  'wiki-support', :user => User.systemuser, :alias_type => EmailAlias::SYSTEM_FORWARD, :destination => 'wiki-support@mail.extension.org')

  end

  def self.down
    drop_table "email_aliases"
  end
end



