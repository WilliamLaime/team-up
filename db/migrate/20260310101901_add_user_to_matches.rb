class AddUserToMatches < ActiveRecord::Migration[8.1]
  def change
    # null: true car il peut y avoir des matchs existants sans user_id en base de développement
    add_reference :matches, :user, null: true, foreign_key: true
  end
end
