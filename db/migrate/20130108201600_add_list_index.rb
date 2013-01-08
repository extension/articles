class AddListIndex < ActiveRecord::Migration
  def self.up
    # drop a mailing list created by mistake
    list = List.find_by_name('urbanipm-cop-members')
    list.destroy

    # for good measure = set the community for announce and mailman to 0 and type to 'all'
    announce = List.find_by_name('announce')
    mailman = List.find_by_name('mailman')
    announce.update_attributes({:community_id => 0, :connectiontype => 'announce'})
    mailman.update_attributes({:community_id => 0, :connectiontype => 'mailman'})

    add_index "lists", ["name"], :name => "name_ndx", :unique => true
    add_index "lists", ["community_id","connectiontype"], :name => "community_type_ndx", :unique => true
  end

  def self.down
  end
end
