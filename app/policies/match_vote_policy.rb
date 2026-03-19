class MatchVotePolicy < ApplicationPolicy
  # Seul un utilisateur connecté peut voter,
  # et on ne peut pas voter pour soi-même (validé aussi dans le modèle)
  def create?
    user.present? && user != record.voted_for
  end
end
