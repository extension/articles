class CreateAdminAccounts < ActiveRecord::Migration
  def self.up
    add_column(:accounts, :primary_account, :integer)
    Account.reset_column_information
    current_admin_list = User.where(:is_admin => true).all
    current_admin_list.each do |admin|
      admin.create_admin_account
      admin.update_attribute(:is_admin,false)
    end
  end

  def self.down
  end
end
