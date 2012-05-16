class AddSpecialPages < ActiveRecord::Migration
  def self.up
    create_table "special_pages", :force => true do |t|
      t.string   "path"
      t.string   "titletag"
      t.string   "main_heading"
      t.string   "sub_heading"
      t.integer  "page_id"
    end
    
    add_index "special_pages", ['path'], :name => 'path_ndx', :unique => true
    add_index "special_pages", ['page_id'], :name => 'page_ndx', :unique => true
    
    # add a flag to pages to avoid unnecessary joins on checks
    add_column "pages", "is_special_page", :boolean, :default => false
    
    # data
    SpecialPage.reset_column_information
    Page.reset_column_information
    
    # communities
    SpecialPage.create(:path => 'communities',
                       :titletag => 'eXtension - Resource Areas',
                       :main_heading => 'Resource Areas',
                       :sub_heading => 'eXtension content is organized around resource areas. See which areas might make a connection with you.',
                       :page => Page.find_by_title_url("eXtension_Resource_Areas"))
    
    # about             
    SpecialPage.create(:path => 'about',
                       :titletag => 'About eXtension - Our origins and what we have to offer',
                       :main_heading => 'About',
                       :sub_heading => 'Read about our origins and what we have to offer online.',
                       :page => Page.find_by_title_url("eXtension_About"))

    # contact_us             
    SpecialPage.create(:path => 'contact_us',
                       :titletag => 'eXtension - Contact Us',
                       :main_heading => 'Contact Us',
                       :sub_heading => 'Your comments and questions are very important to us. Your quality feedback makes a tremendous impact on improving our site.',
                       :page => Page.find_by_title_url("eXtension_Contact_Us"))
    
    # privacy             
    SpecialPage.create(:path => 'privacy',
                       :titletag => 'eXtension - Privacy Policy',
                       :main_heading => 'Privacy Policy',
                       :sub_heading => 'We have developed this privacy statement in order to demonstrate our commitment to safeguarding the privacy of those who use the eXtension web site.',
                       :page => Page.find_by_title_url("eXtension_Privacy_Policy"))

    # termsofuse             
    SpecialPage.create(:path => 'termsofuse',
                       :titletag => 'eXtension - Terms of Use',
                       :main_heading => 'Terms of Use',
                       :sub_heading => 'Please read terms of use before using this site.',
                       :page => Page.find_by_title_url("eXtension_Terms_of_Use"))
    # disclaimer             
    SpecialPage.create(:path => 'disclaimer',
                       :titletag => 'eXtension - Legal Disclaimer',
                       :main_heading => 'Legal Disclaimer',
                       :sub_heading => 'Please read the disclaimer before using this site.',
                       :page => Page.find_by_title_url("eXtension_Disclaimer"))
    # partners             
    SpecialPage.create(:path => 'partners',
                       :titletag => 'eXtension - Partners',
                       :main_heading => 'Partners',
                       :sub_heading => 'Without our partners, eXtension would not be possible.',
                       :page => Page.find_by_title_url("eXtension_Partners"))    
    
  end 
  
  def self.down
    remove_column "pages", "is_special_page"
    drop_table "special_pages"
  end
end
