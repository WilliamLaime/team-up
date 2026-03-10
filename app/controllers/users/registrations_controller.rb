# Ce controller surcharge le controller d'inscription de Devise
# pour créer automatiquement un profil avec le prénom et le nom
class Users::RegistrationsController < Devise::RegistrationsController
  # Après la création du compte, on crée le profil avec prénom et nom
  def create
    super do |user|
      # Ce bloc s'exécute après la création de l'utilisateur
      # Si l'utilisateur vient d'être sauvegardé (pas d'erreurs), on crée le profil
      if user.persisted?
        user.create_profil(
          first_name: sign_up_params[:first_name],
          last_name:  sign_up_params[:last_name]
        )
      end
    end
  end

  private

  # On ajoute first_name et last_name aux paramètres autorisés par Devise
  def sign_up_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      :first_name, :last_name
    )
  end
end
