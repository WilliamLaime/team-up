class AddGenreRestrictionToMatches < ActiveRecord::Migration[8.1]
  def change
    # default: "tous" → les matchs existants acceptent tout le monde automatiquement
    add_column :matches, :genre_restriction, :string, default: "tous"
  end
end
