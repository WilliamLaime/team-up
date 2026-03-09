Rails.application.routes.draw do
  devise_for :users

  # Page d'accueil
  root to: "pages#home"

  # Routes pour les matchs (CRUD complet)
  # Exemple : GET /matches => liste, GET /matches/1 => détail, etc.
  resources :matches do
    # Routes imbriquées pour rejoindre/quitter un match
    # POST   /matches/:match_id/match_users     => rejoindre
    # DELETE /matches/:match_id/match_users/:id => quitter
    resources :match_users, only: [:create, :destroy]
  end

  # Route pour le profil de l'utilisateur connecté (ressource singulière)
  # GET  /profil      => voir mon profil
  # GET  /profil/edit => modifier mon profil
  # PUT  /profil      => sauvegarder les modifications
  resource :profil, only: [:show, :edit, :update]

  # Vérification de santé de l'application
  get "up" => "rails/health#show", as: :rails_health_check
end
