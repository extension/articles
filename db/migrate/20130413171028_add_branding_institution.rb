class AddBrandingInstitution < ActiveRecord::Migration
  def self.up

    create_table "branding_institutions", :force => true do |t|
      t.string   "name",                                                     :null => false
      t.integer  "location_id",                           :default => 0
      t.string   "public_uri"
      t.string   "referer_domain"
      t.string   "institution_code",        :limit => 10
      t.integer  "logo_id",                               :default => 0
      t.timestamps
    end

    add_index "branding_institutions", ["name"], :name => "name_ndx", :unique => true
    add_index "branding_institutions", ["referer_domain"], :name => "referer_ndx"
    add_index "branding_institutions", ["location_id"], :name => "location_ndx"
     
    BrandingInstitution.reset_column_information
    Community.institutions.where(:show_in_public_list => true).all.each do |i|
      bi = BrandingInstitution.new
      bi.name = i.name
      bi.location_id = i.location_id
      bi.public_uri = i.public_uri
      bi.referer_domain = i.referer_domain
      bi.institution_code = i.institution_code
      bi.logo_id = i.logo_id
      bi.save

      if(!bi.logo_id.blank? and bi.logo_id > 0 )
        execute("UPDATE logos SET logotype = #{Logo::INSTITUTION} where id = #{bi.logo_id}")
      end
    end


  end

  def self.down
    drop_table("branding_institutions")
  end
end
