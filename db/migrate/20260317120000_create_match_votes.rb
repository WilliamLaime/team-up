class CreateMatchVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :match_votes do |t|
      # L'utilisateur qui vote
      t.references :voter,      null: false, foreign_key: { to_table: :users }
      # Le match concerné
      t.references :match,      null: false, foreign_key: true
      # L'utilisateur pour qui on vote (l'homme du match)
      t.references :voted_for,  null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Un seul vote par votant par match (pas de double vote)
    add_index :match_votes, [:voter_id, :match_id], unique: true
  end
end
