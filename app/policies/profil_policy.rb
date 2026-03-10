class ProfilPolicy < ApplicationPolicy
  # Tout utilisateur peut voir son propre profil
  def show?
    record.user == user
  end

  # Seul le propriétaire peut modifier son profil
  # edit? appelle automatiquement update? (défini dans ApplicationPolicy)
  def update?
    record.user == user
  end
end
