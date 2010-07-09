class ModifyAnnotationEvent < ActiveRecord::Migration
  def self.up
    rename_column(:annotation_events, :ipaddr, :ip)
    add_column(:annotation_events, :login, :string)
    add_column(:annotation_events, :additionaldata, :text)
    AnnotationEvent.all.each {|a| a.update_attribute :login, 'peoplebot'}
  end

  def self.down
    rename_column(:annotation_events, :ip, :ipaddr)
    remove_column(:annotation_events, :login)
    remove_column(:annotation_events, :additionaldata)
  end
end
