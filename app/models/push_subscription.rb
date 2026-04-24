# Stocke les subscriptions Web Push d'un utilisateur.
# Un user peut avoir plusieurs subscriptions (plusieurs appareils/navigateurs).
# Chaque subscription est identifiée par son endpoint unique fourni par le navigateur.
class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: { scope: :user_id }
  validates :p256dh,   presence: true
  validates :auth,     presence: true
end
