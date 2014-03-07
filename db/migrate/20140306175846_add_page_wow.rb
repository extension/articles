class AddPageWow < ActiveRecord::Migration
  def change
    add_column :pages, :summary, :text
  end

end
