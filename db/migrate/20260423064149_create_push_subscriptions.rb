class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false  # URL unique fournie par le navigateur
      t.string :p256dh,   null: false  # Clé publique chiffrée du navigateur
      t.string :auth,     null: false  # Secret d'authentification du navigateur
      t.timestamps
    end

    # Un user ne peut pas avoir deux fois le même endpoint (même appareil)
    add_index :push_subscriptions, [:user_id, :endpoint], unique: true
  end
end
