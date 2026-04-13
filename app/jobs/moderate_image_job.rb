# Job async qui lance la modération IA d'une image utilisateur.
#
# Enqueued automatiquement par le concern `Moderatable` (Phase 2) à chaque
# changement d'un attachement modéré, et manuellement par la rake task
# `moderation:check_existing` pour les images déjà en base (Phase 6).
#
# Usage :
#   ModerateImageJob.perform_later(profil, "avatar")
#   ModerateImageJob.perform_later(team,   "badge_image")
#
# Active Job sérialise automatiquement le record via GlobalID (tous les
# ActiveRecord sont GlobalID-compatibles), donc on peut passer le record tel
# quel en premier argument. Rails le recharge fraîchement depuis la DB au
# moment du `perform`, ce qui évite les problèmes de stale data.
#
# Comportement sur erreur :
#   - RateLimitError / ApiError → retry avec backoff polynomial, max 5x
#   - QuotaExceededError        → PAS de retry (géré directement par le Checker
#                                  qui passe en errored)
#   - RecordNotFound            → discard (le record a été supprimé entre-temps,
#                                  plus rien à modérer)
class ModerateImageJob < ApplicationJob
  queue_as :default

  # Retry avec délai croissant : 3s, 18s, 83s, 258s, 623s (polynomial wait).
  # Donne le temps à un rate limit Sightengine de se relâcher ou à un serveur
  # 5xx de se remettre debout. Au-delà de 5 tentatives, on abandonne et le
  # job passe en failed dans Solid Queue (visible dans la dashboard admin si
  # tu veux en ajouter une plus tard).
  retry_on ImageModeration::ApiError,
           wait: :polynomially_longer,
           attempts: 5

  retry_on ImageModeration::RateLimitError,
           wait: :polynomially_longer,
           attempts: 5

  # Si le record (Profil/Team) a été supprimé entre l'enqueue et l'exécution,
  # on ignore silencieusement le job. GlobalID lève RecordNotFound au moment
  # de la désérialisation dans ce cas.
  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound

  def perform(record, attachment_name)
    ImageModeration::Checker.call(record, attachment_name)
  end
end
