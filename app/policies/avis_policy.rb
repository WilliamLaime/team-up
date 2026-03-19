class AvisPolicy < ApplicationPolicy
  # Seule action disponible : créer un avis
  # Conditions minimales vérifiées ici (les règles métier détaillées sont dans le modèle Avis)
  def create?
    # L'utilisateur doit être connecté
    return false unless user.present?

    # On ne peut pas se noter soi-même
    return false if user == record.reviewed_user

    true
  end
end
