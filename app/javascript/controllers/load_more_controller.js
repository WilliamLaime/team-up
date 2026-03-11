// Stimulus controller pour le bouton "Afficher plus de matchs"
// Il affiche les cartes par lot (6 par défaut) sans recharger la page.
// Compatible avec ActionCable : gère les nouvelles cartes ajoutées en temps réel par Turbo Stream.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // On cible chaque carte et le bouton "afficher plus"
  static targets = ["card", "button"]

  // Valeurs configurables depuis le HTML (data-load-more-step-value="6")
  static values = {
    step: { type: Number, default: 6 }, // Nombre de cartes à révéler par clic
    visible: Number                      // Nombre de cartes actuellement visibles
  }

  // Appelé automatiquement quand le controller est attaché au DOM
  connect() {
    // Flag interne : tant qu'il est false, cardTargetConnected ne fait rien
    // (évite de s'exécuter sur les cartes déjà présentes au chargement)
    this._ready = false

    // On commence par afficher seulement le premier "lot" de cartes
    this.visibleValue = this.stepValue
    this.updateVisibility()

    // À partir de maintenant, les nouvelles cartes Turbo seront gérées
    this._ready = true
  }

  // Appelé quand on clique sur le bouton "Afficher plus"
  more() {
    // On augmente le nombre de cartes visibles d'un lot
    this.visibleValue += this.stepValue
    this.updateVisibility()
  }

  // ── ActionCable : nouvelle carte ajoutée par Turbo Stream ─────────────────
  // Stimulus appelle cette méthode automatiquement quand un nouvel élément
  // avec data-load-more-target="card" est ajouté au DOM (ex: broadcast après création d'un match)
  cardTargetConnected(element) {
    // On ignore les cartes présentes dès le chargement initial
    if (!this._ready) return

    // Nouvelle carte en temps réel → on l'affiche immédiatement
    element.classList.remove("d-none")

    // On recalcule le nombre de cartes visibles pour garder le bouton cohérent
    this.visibleValue = this.cardTargets.filter(c => !c.classList.contains("d-none")).length

    // Met à jour le bouton (caché si tout est visible)
    this._updateButton()
  }

  // Met à jour quelles cartes sont visibles ou cachées
  updateVisibility() {
    this.cardTargets.forEach((card, index) => {
      if (index < this.visibleValue) {
        // Cette carte fait partie du lot visible → on l'affiche
        card.classList.remove("d-none")
      } else {
        // Cette carte est au-delà du lot visible → on la cache
        card.classList.add("d-none")
      }
    })

    this._updateButton()
  }

  // ── Méthode privée ──────────────────────────────────────────────────────
  // Cache le bouton si toutes les cartes sont déjà visibles, sinon l'affiche
  _updateButton() {
    if (this.visibleValue >= this.cardTargets.length) {
      this.buttonTarget.classList.add("d-none")
    } else {
      this.buttonTarget.classList.remove("d-none")
    }
  }
}
