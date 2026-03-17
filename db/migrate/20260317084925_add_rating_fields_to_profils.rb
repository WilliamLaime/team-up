class AddRatingFieldsToProfils < ActiveRecord::Migration[8.1]
  def change
    # Moyenne des notes reçues (ex: 4.3), recalculée à chaque nouvel avis
    add_column :profils, :average_rating, :float,   default: 0.0
    # Nombre total d'avis reçus
    add_column :profils, :avis_count,     :integer, default: 0
  end
end
