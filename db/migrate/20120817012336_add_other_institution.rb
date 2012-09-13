class AddOtherInstitution < ActiveRecord::Migration
  def self.up
    add_column('accounts', 'affiliation', :string)
  end

  def self.down
    remove_column('accounts', 'affiliation')
  end
end
