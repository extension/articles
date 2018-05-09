class DropUnusedFieldsFromInstitutions < ActiveRecord::Migration
  def up
    remove_column(:branding_institutions, :institution_code)
  end
end
