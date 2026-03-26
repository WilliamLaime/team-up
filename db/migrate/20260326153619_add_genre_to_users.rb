class AddGenreToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :genre, :string
  end
end
