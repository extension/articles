class CreateSystemUsers < ActiveRecord::Migration
  def self.up
    sysuser_query = "INSERT INTO users (id,login,first_name,last_name,email,retired,vouched,email_event_at,created_at,updated_at) VALUES "
    sysuser_query += " (2,'systemsmirror','Mirror','Systems','systemsmirror@extension.org',0,1,NOW(),NOW(),NOW()),"
    sysuser_query += "(3,'systemsreplies','Replies','Systems','systemsreplies@extension.org',0,1,NOW(),NOW(),NOW()),"
    sysuser_query += "(4,'systemsaae','AskAnExpert','Systems','systemsaae@extension.org',0,1,NOW(),NOW(),NOW())"
    execute sysuser_query
    
    # email aliases
    EmailAlias.create(:user => User.find_by_login('systemsmirror'), :alias_type => EmailAlias::INDIVIDUAL_GOOGLEAPPS)
    EmailAlias.create(:user => User.find_by_login('systemsreplies'), :alias_type => EmailAlias::INDIVIDUAL_GOOGLEAPPS)
    EmailAlias.create(:user => User.find_by_login('systemsaae'), :alias_type => EmailAlias::INDIVIDUAL_GOOGLEAPPS)
    
  end

  def self.down
  end
end
