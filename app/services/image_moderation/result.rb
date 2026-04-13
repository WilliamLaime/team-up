# Value object retourné par un adapter après analyse d'une image.
#
# Pourquoi un objet dédié plutôt qu'un hash ? Parce que le Checker consomme ce
# résultat de plusieurs manières (comparer au seuil, sauvegarder en base,
# logger) et qu'un objet typé avec des méthodes explicites est plus lisible
# qu'un `hash[:score]` disséminé dans le code. Ça isole aussi le Checker des
# changements de format interne : si un jour on ajoute une `label` plus fine,
# on l'ajoute ici sans toucher au reste.
#
# Les adapters ne manipulent que des `Result`. Le Checker ne manipule que des
# `Result`. Aucun de ces deux composants ne connaît la forme exacte de la
# réponse API du provider — c'est l'adapter qui traduit la réponse brute en
# `Result`, et c'est le seul endroit à changer quand on switche de provider.
#
# Note Zeitwerk : on `reopen` la classe ImageModeration (définie dans le
# modèle) plutôt que de déclarer un module. C'est obligatoire parce que
# ImageModeration est une classe ActiveRecord — tenter `module ImageModeration`
# lèverait une TypeError au chargement.
class ImageModeration
  class Result
    # @return [Float] score NSFW dans [0, 1] — 0 = safe, 1 = certainement NSFW
    attr_reader :score

    # @return [Symbol] :safe ou :nsfw, dérivé du score par rapport au seuil
    attr_reader :label

    # @return [Hash] réponse brute du provider, conservée pour debug/admin
    attr_reader :raw

    def initialize(score:, raw: {})
      @score = score.to_f
      @label = @score >= ImageModeration::NSFW_THRESHOLD ? :nsfw : :safe
      @raw   = raw
    end

    # Vrai si l'image doit être rejetée. Délègue à la comparaison au seuil pour
    # que le Checker n'ait pas à connaître la constante directement.
    def nsfw?
      label == :nsfw
    end
  end
end
