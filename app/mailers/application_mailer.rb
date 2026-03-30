class ApplicationMailer < ActionMailer::Base
  # Utilise la variable d'environnement MAILER_FROM (définie sur Heroku)
  # Cette adresse doit être vérifiée comme "Sender Identity" dans SendGrid
  default from: ENV.fetch("MAILER_FROM", "noreply@teams-up-sport.fr")
  layout "mailer"
end
