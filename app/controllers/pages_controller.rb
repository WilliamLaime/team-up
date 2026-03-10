class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  # Rails 7.1 vérifie au chargement que les actions dans `only:` existent.
  # PagesController n'a pas d'action `index`, donc on désactive les callbacks Pundit.
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def home
    # Récupère les 3 prochains matchs à venir, triés par date
    @matches = Match.order(date: :asc).limit(3)
  end
end
