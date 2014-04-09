class AddBrandingFlag < ActiveRecord::Migration
  def change
    add_column :branding_institutions, :is_active, :boolean, default: true
  end
end
