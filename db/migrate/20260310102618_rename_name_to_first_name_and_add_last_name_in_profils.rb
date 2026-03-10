class RenameNameToFirstNameAndAddLastNameInProfils < ActiveRecord::Migration[8.1]
  def change
    # Renomme la colonne "name" en "first_name"
    rename_column :profils, :name, :first_name
    # Ajoute la colonne "last_name"
    add_column :profils, :last_name, :string
  end
end
