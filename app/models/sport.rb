# Modèle Sport — représente un sport (Football, Tennis, Padel, etc.)
# Champs :
#   name : nom affiché (ex: "Football")
#   icon : emoji du sport (ex: "⚽")
#   slug : identifiant URL-friendly (ex: "football")
class Sport < ApplicationRecord
  # Un sport peut être pratiqué par plusieurs utilisateurs via la table user_sports
  has_many :user_sports, dependent: :destroy
  has_many :users, through: :user_sports

  # Un sport peut avoir plusieurs matchs associés
  has_many :matches, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :icon, presence: true

  # Formats disponibles pour ce sport
  # Chaque format = { label: "5v5", players: 9 }
  # players = joueurs manquants (organisateur déjà compté)
  # players: nil → format Libre (taille libre, sans contrainte de max)
  def available_formats
    libre = { label: "Libre", players: nil }
    case slug
    when "football"   then [{ label: "5v5",  players: 9  }, { label: "11v11", players: 21 }, libre]
    when "tennis"     then [{ label: "1v1",  players: 1  }, { label: "2v2", players: 3 }, libre]
    when "padel"      then [{ label: "2v2",  players: 3  }, libre]
    when "volleyball" then [{ label: "3v3",  players: 5  }, { label: "6v6", players: 11 }, libre]
    when "basketball" then [{ label: "1v1", players: 1 }, { label: "2v2", players: 3 }, { label: "3v3", players: 5 },
                            { label: "5v5", players: 9 }, libre]
    when "handball"   then [{ label: "6v6",  players: 11 }, libre]
    when "badminton"  then [{ label: "1v1",  players: 1  }, { label: "2v2", players: 3 }, libre]
    else                   [libre]
    end
  end

  # Nombre de joueurs par défaut = premier format du sport (garde-fou si nil)
  def default_player_count
    available_formats.first[:players] || 1
  end

  # Max de joueurs = plus grand format du sport (compact exclut le nil du format Libre)
  def max_player_count
    available_formats.map { |f| f[:players] }.compact.max
  end
end
