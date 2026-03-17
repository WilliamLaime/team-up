// Controller Stimulus : scroll_to_error
// Se connecte automatiquement à chaque chargement de page.
// Si des erreurs de formulaire sont présentes, il fait défiler la page
// jusqu'à la première erreur visible — pratique sur mobile ou formulaires longs.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Cherche la première erreur dans cet ordre de priorité :
    // 1. .field_with_errors            → champ individuel entouré par Rails
    // 2. .text-danger:not(.d-none)     → erreur inline (ex: sport non sélectionné)
    // 3. .error-notification           → message global en haut du formulaire
    const firstError = this.element.querySelector(
      ".field_with_errors, .text-danger:not(.d-none), .error-notification"
    )

    if (firstError) {
      // Léger délai pour laisser le navigateur finir de rendre la page
      // avant de déclencher le scroll (nécessaire avec Turbo)
      setTimeout(() => {
        firstError.scrollIntoView({ behavior: "smooth", block: "center" })
      }, 100)
    }
  }
}
