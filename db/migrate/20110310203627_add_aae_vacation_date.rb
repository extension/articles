class AddAaeVacationDate < ActiveRecord::Migration
  def self.up
    add_column(:accounts, :vacated_aae_at, :datetime)
  end

  def self.down
  end
end
