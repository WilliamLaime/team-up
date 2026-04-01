class AddPlayersPresentToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :players_present, :integer
  end
end
