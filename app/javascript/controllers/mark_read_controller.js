// Stimulus controller : mark-read
// Quand on clique "Lire" :
//   1. Soumet le formulaire caché via requestSubmit() → Turbo intercepte et traite la réponse
//      Turbo Stream (remplace la ligne du tableau, met à jour les badges via broadcast)
//   2. Ouvre la modale Bootstrap correspondante

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // "form"  → le formulaire caché (soumis en arrière-plan par Turbo)
  // "modal" → sélecteur CSS de la modale à ouvrir (ex: "#modal-message-42")
  static targets = ["form"]
  static values  = { modal: String }

  send() {
    // requestSubmit() soumet le formulaire comme si l'utilisateur avait cliqué submit.
    // Turbo intercepte cette soumission, envoie le PATCH, et traite la réponse Turbo Stream
    // → la ligne du tableau est remplacée + les broadcasts de badges sont envoyés par le modèle.
    // On vérifie que le formulaire existe avant de soumettre
    // (si le message est déjà lu, le serveur ne fait rien grâce au "unless lu?")
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }

    // Ouvre la modale Bootstrap après la soumission du formulaire
    // bootstrap.Modal.getOrCreateInstance() évite les conflits si la modale est déjà ouverte
    const modalEl = document.querySelector(this.modalValue)
    if (modalEl) {
      bootstrap.Modal.getOrCreateInstance(modalEl).show()
    }
  }
}
