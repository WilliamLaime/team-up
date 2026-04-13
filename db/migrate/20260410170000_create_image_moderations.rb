class CreateImageModerations < ActiveRecord::Migration[8.1]
  # Table polymorphique qui centralise le résultat de la modération IA de toutes
  # les images uploadées par les utilisateurs (avatar de profil, blason et
  # bannière d'équipe). Une seule table évite de dupliquer la logique et la
  # table d'admin pour chaque type de modèle modéré.
  def change
    create_table :image_moderations do |t|
      # Association polymorphique : pointe soit vers un Profil, soit vers un Team.
      # `polymorphic: true` crée automatiquement les colonnes `moderatable_type`
      # (string) et `moderatable_id` (bigint) avec un index composé.
      t.references :moderatable, polymorphic: true, null: false, index: false

      # Nom de l'attachement Active Storage concerné : "avatar" pour Profil,
      # "badge_image" ou "cover_image" pour Team. Permet de distinguer les deux
      # attachements d'un Team tout en gardant une seule ligne par couple
      # (record, attachment).
      t.string :attachment_name, null: false

      # Statut de la modération :
      #   - pending  : job enfilé, pas encore traité
      #   - approved : score sous le seuil, image OK
      #   - rejected : score ≥ seuil, image purgée
      #   - errored  : erreur API ou quota dépassé (fail-open : image visible)
      # Stocké en string plutôt qu'integer pour lisibilité en base et en logs.
      t.string :status, null: false, default: "pending"

      # Score NSFW retourné par l'adapter (max des 4 catégories explicites).
      # decimal(5,4) permet de stocker 0.0000 à 9.9999 avec 4 décimales, soit
      # une précision largement suffisante pour comparer à un seuil 0.8.
      t.decimal :score, precision: 5, scale: 4

      # Raison du verdict pour l'admin :
      #   "nsfw_detected"  → rejeté sur score
      #   "safe"           → approuvé
      #   "api_error"      → erreur réseau/5xx
      #   "quota_exceeded" → free tier Sightengine épuisé
      t.string :reason

      # Horodatage du dernier appel à l'API de modération (différent de
      # updated_at, qui peut changer pour d'autres raisons comme un re-modérate
      # manuel depuis l'admin).
      t.datetime :checked_at

      # Provider utilisé pour cette modération ("sightengine" au lancement).
      # Permet, le jour où on change d'adapter, de savoir quelles lignes ont
      # été traitées par qui sans relancer tout l'historique.
      t.string :provider, null: false, default: "sightengine"

      t.timestamps
    end

    # Index unique sur le triplet (type, id, attachment_name) : une seule ligne
    # par couple (record, attachment) dans la table. Si on re-modère (via admin
    # ou rake task), on met à jour la ligne existante plutôt que d'en créer une
    # nouvelle. Garde l'historique propre et simplifie les lookups.
    add_index :image_moderations,
              %i[moderatable_type moderatable_id attachment_name],
              unique: true,
              name: "index_image_moderations_on_moderatable_and_attachment"

    # Index sur status pour filtrer rapidement dans l'admin (ex : "montre-moi
    # tous les rejected de cette semaine").
    add_index :image_moderations, :status

    # Index sur checked_at pour la requête "quota utilisé ce mois-ci" qui alimente
    # l'alerte 80%. Un scan indexé sur une plage datetime est beaucoup plus rapide
    # qu'un full scan dès que la table grossit.
    add_index :image_moderations, :checked_at
  end
end
