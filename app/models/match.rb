class Match < ApplicationRecord
  # Le créateur du match (organisateur)
  belongs_to :user, optional: true
  has_many :match_users
  has_many :users, through: :match_users

  # Modes de validation disponibles pour l'organisateur
  VALIDATION_MODES = ["automatic", "manual"].freeze

  # Retourne vrai si le match est en mode validation manuelle
  def manual_validation?
    validation_mode == "manual"
  end

  # Retourne l'inscription de l'organisateur du match
  def organizer_match_user
    match_users.find_by(role: "organisateur")
  end
end
