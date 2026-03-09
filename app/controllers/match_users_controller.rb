class MatchUsersController < ApplicationController
  # Retrouver le match parent avant chaque action
  before_action :set_match

  # POST /matches/:match_id/match_users
  # Rejoindre un match
  def create
    # Vérifie si l'utilisateur est déjà inscrit à ce match
    if @match.match_users.exists?(user: current_user)
      redirect_to @match, alert: "Tu es déjà inscrit à ce match."
      return
    end

    # Crée l'inscription avec le rôle "joueur"
    @match_user = @match.match_users.new(user: current_user, role: "joueur")

    if @match_user.save
      redirect_to @match, notice: "Tu as rejoint le match !"
    else
      redirect_to @match, alert: "Impossible de rejoindre le match."
    end
  end

  # DELETE /matches/:match_id/match_users/:id
  # Quitter un match
  def destroy
    # Retrouve l'inscription de l'utilisateur connecté
    @match_user = @match.match_users.find(params[:id])

    # Vérifie que l'utilisateur peut seulement quitter sa propre inscription
    if @match_user.user == current_user
      @match_user.destroy
      redirect_to @match, notice: "Tu as quitté le match."
    else
      redirect_to @match, alert: "Action non autorisée."
    end
  end

  private

  # Retrouve le match parent via l'id dans l'URL
  def set_match
    @match = Match.find(params[:match_id])
  end
end
