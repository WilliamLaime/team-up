class Notification < ApplicationRecord
  belongs_to :user

  # Scope pour récupérer uniquement les notifications non lues
  scope :unread, -> { where(read: false) }

  # Scope pour trier du plus récent au plus ancien
  scope :recent, -> { order(created_at: :desc) }

  # ── ActionCable : mise à jour en temps réel de la cloche ──────────────────
  # Quand une notification est créée, on remplace la cloche dans la navbar
  # de l'utilisateur concerné — sans qu'il ait besoin de recharger la page.
  #
  # Canal personnalisé par utilisateur : "notifications_user_42" (ex pour user id=42)
  # La navbar s'abonne avec : <%= turbo_stream_from current_user, :notifications %>
  after_create_commit :broadcast_notification_bell

  private

  def broadcast_notification_bell
    # Remplace le fragment "notification_bell" dans la navbar de l'utilisateur destinataire
    broadcast_replace_to(
      [user, :notifications],          # canal unique pour cet utilisateur
      target: "notification_bell",     # id du turbo_frame dans la navbar
      partial: "shared/notification_bell",
      locals: { current_user: user }   # on passe l'utilisateur au partial
    )
  end
end
