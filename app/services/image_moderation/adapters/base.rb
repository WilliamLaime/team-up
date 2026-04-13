# Interface abstraite que tout adapter de modération d'images doit respecter.
#
# L'existence de cette classe est la raison d'être du pattern adapter dans ce
# module : le jour où on change de provider (Sightengine → autre chose), le
# Checker ne doit rien changer. On écrit un nouvel adapter qui implémente
# `#analyze` et on le branche via `ImageModeration.adapter = NewAdapter.new`.
#
# Tout adapter concret hérite de Base et doit implémenter `#analyze(io, filename:)`.
# Le contrat est strict : la méthode reçoit un IO (déjà ouvert par le Checker),
# le nom de fichier original pour les requêtes multipart qui en ont besoin,
# et doit retourner un `ImageModeration::Result`. En cas d'erreur, lever une
# exception de la hiérarchie `ImageModeration::Error`.
class ImageModeration
  module Adapters
    class Base
      # @param io [IO] flux binaire de l'image à analyser (lu depuis le blob
      #   Active Storage ou un fichier temporaire)
      # @param filename [String] nom de fichier original (ex: "avatar.jpg"),
      #   utilisé par certains providers pour déterminer le content-type
      # @return [ImageModeration::Result]
      # @raise [ImageModeration::ApiError] erreur réseau ou serveur
      # @raise [ImageModeration::RateLimitError] HTTP 429
      # @raise [ImageModeration::QuotaExceededError] quota mensuel dépassé
      def analyze(io, filename:)
        raise NotImplementedError, "#{self.class.name} must implement #analyze(io, filename:)"
      end

      # Identifiant textuel du provider, stocké dans la colonne `provider` de
      # la table image_moderations. Permet de filtrer l'historique par provider
      # dans l'admin et de savoir quelles lignes ont été analysées par qui.
      # Par défaut dérivé du nom de classe, surcharger si besoin.
      def provider_name
        self.class.name.demodulize.underscore
      end
    end
  end
end
