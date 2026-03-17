class AddHommeDuMatchFields < ActiveRecord::Migration[8.0]
  def change
    # Sur le match : stocke le gagnant actuel (recalculé à chaque vote)
    # null: true car pas de gagnant tant qu'il n'y a aucun vote
    add_reference :matches, :homme_du_match, foreign_key: { to_table: :users }, null: true

    # Sur le profil : compteur du nombre de fois que le joueur a été élu homme du match
    add_column :profils, :homme_du_match_count, :integer, default: 0, null: false
  end
end
