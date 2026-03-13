class AddImageToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :image, :string
  end
end
