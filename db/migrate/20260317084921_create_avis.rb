class CreateAvis < ActiveRecord::Migration[8.1]
  def change
    create_table :avis do |t|
      # Celui qui laisse l'avis
      t.references :reviewer,      null: false, foreign_key: { to_table: :users }
      # Celui qui reçoit l'avis
      t.references :reviewed_user, null: false, foreign_key: { to_table: :users }
      # Le match qui a réuni les deux joueurs
      t.references :match,         null: false, foreign_key: true
      # Note de 1 à 5 étoiles
      t.integer    :rating,        null: false
      # Commentaire optionnel
      t.text       :content

      t.timestamps
    end

    # Empêche de laisser deux avis pour la même personne dans le même match
    add_index :avis, [:reviewer_id, :reviewed_user_id, :match_id], unique: true
  end
end
