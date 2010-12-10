class AddAdditionalFieldsToContentLinks < ActiveRecord::Migration
  def self.up
    add_column(:content_links, :status, :integer)
    add_column(:content_links, :error_count, :integer, :default => 0)
    add_column(:content_links, :last_check_at, :datetime)
    add_column(:content_links, :last_check_status, :integer)
    add_column(:content_links, :last_check_response, :boolean)
    add_column(:content_links, :last_check_code, :string)
    add_column(:content_links, :last_check_information, :text)    
  end

  def self.down
    remove_column(:content_links, :status)
    remove_column(:content_links, :error_count)
    remove_column(:content_links, :last_check_at)
    remove_column(:content_links, :last_check_status)
    remove_column(:content_links, :last_check_response)
    remove_column(:content_links, :last_check_code)
    remove_column(:content_links, :last_check_information)
  end
end
