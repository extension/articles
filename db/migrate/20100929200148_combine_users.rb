class CombineUsers < ActiveRecord::Migration
  def self.up
    # copy the table
    execute "CREATE TABLE accounts LIKE users;"
    execute "INSERT accounts SELECT * FROM users;"
    # add type column
    execute "ALTER TABLE `accounts` ADD COLUMN `type` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT ''  AFTER `id`;"
    # set them all to user
    execute "UPDATE accounts SET type = 'User'"
    
    # allow null passwords
    execute "ALTER TABLE `accounts` CHANGE COLUMN `password` `password` VARCHAR(40) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;"
    
    
    # will be used to generate eXtensionID's later
    add_column(:accounts, :base_login_string, :string)
    add_column(:accounts, :login_increment, :integer)
  
    # login string and increment
    execute "UPDATE accounts SET base_login_string = login, login_increment = 1"
  
    # insert all the public users,  increment and base_string close enough for government work
    execute "INSERT IGNORE INTO accounts (type,login,email,first_name,last_name,created_at,updated_at,base_login_string,login_increment) SELECT 'PublicUser',CONCAT('public',id),email,first_name,last_name,created_at,updated_at,'public',id FROM public_users"
    
    # set first and last names
    execute "UPDATE accounts SET first_name = 'Anonymous' where first_name IS NULL"
    execute "UPDATE accounts SET last_name = 'Guest' where last_name IS NULL"
        
  end

  def self.down
  end
end
