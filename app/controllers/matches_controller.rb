class MatchesController < ApplicationController
  # Retrouver le match avant les actions qui en ont besoin
  before_action :set_match, only: [:show, :edit, :update, :destroy]

  # GET /matches
  # Affiche la liste de tous les matchs
  def index
    # policy_scope filtre les matchs selon les règles de MatchPolicy::Scope
    @matches = policy_scope(Match).order(date: :asc)
  end

  # GET /matches/:id
  # Affiche le détail d'un match
  def show
    # Récupère les participants du match
    @match_users = @match.match_users.includes(:user)
    authorize @match

    # Vérifie si l'utilisateur connecté est déjà inscrit à ce match
    @current_match_user = @match.match_users.find_by(user: current_user)
  end

  # GET /matches/new
  # Affiche le formulaire de création d'un match
  def new
    @match = Match.new
    authorize @match
  end

  # POST /matches
  # Crée un nouveau match
  def create
    @match = Match.new(match_params)
    @match.user = current_user
    authorize @match


    if @match.save
      # Ajoute automatiquement le créateur comme organisateur approuvé du match
      # status: "approved" car l'organisateur est automatiquement accepté dans son propre match
      @match.match_users.create(user: current_user, role: "organisateur", status: "approved")
      redirect_to @match, notice: "Match créé avec succès !"
    else
      # En cas d'erreur, réaffiche le formulaire
      render :new, status: :unprocessable_entity
    end
  end

  # GET /matches/:id/edit
  # Affiche le formulaire de modification d'un match
  def edit
    authorize @match
  end

  # PATCH/PUT /matches/:id
  # Met à jour un match existant
  def update
    authorize @match
    if @match.update(match_params)
      redirect_to @match, notice: "Match mis à jour avec succès !"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /matches/:id
  # Supprime un match
  def destroy
    authorize @match
    @match.destroy
    redirect_to matches_path, notice: "Match supprimé."
  end

  private

  # Retrouve le match par son id dans les paramètres de l'URL
  def set_match
    @match = Match.find(params[:id])
  end

  # Liste blanche des paramètres autorisés pour créer/modifier un match
  def match_params
    params.require(:match).permit(:title, :description, :date, :time, :place, :level, :player_left, :validation_mode)
  end
end
