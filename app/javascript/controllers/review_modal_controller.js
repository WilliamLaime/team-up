// Stimulus controller : review_modal
// Gère la modal post-match qui apparaît à la connexion pour noter ses coéquipiers
// - Ouvre automatiquement la modal Bootstrap au chargement
// - Soumet les avis en AJAX (fetch) sans recharger la page
// - Marque chaque card comme "Noté ✓" après soumission réussie
// - Ferme la modal quand tous les joueurs sont notés ou sur "Plus tard"

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Turbo met les pages en cache et les restaure lors de la navigation.
    // data-turbo-preview est présent sur <html> quand Turbo affiche une page depuis le cache.
    // On ne veut pas ré-ouvrir la modal sur un aperçu cache → on ignore.
    if (document.documentElement.hasAttribute("data-turbo-preview")) return

    // Ouvre automatiquement la modal Bootstrap dès que le Stimulus controller est connecté
    const modal = bootstrap.Modal.getOrCreateInstance(this.element)
    modal.show()
  }

  // Soumission AJAX d'un formulaire d'avis
  // Appelé par data-action="submit->review-modal#submitReview" sur chaque <form>
  async submitReview(event) {
    event.preventDefault()  // Empêche la soumission HTML classique

    const form     = event.target
    const playerId = event.params.playerId  // data-review-modal-player-id-param
    const matchId  = event.params.matchId   // data-review-modal-match-id-param
    const cardId   = `review-card-${playerId}-${matchId}`
    const card     = document.getElementById(cardId)

    // Vérifie qu'une note a bien été sélectionnée
    const ratingInput = form.querySelector("[data-star-rating-target='input']")
    if (!ratingInput || !ratingInput.value) {
      // Feedback visuel si pas de note sélectionnée
      const starsContainer = form.querySelector("[data-star-rating-target='stars']")
      if (starsContainer) {
        starsContainer.style.outline = "1px solid rgba(255,100,100,0.5)"
        starsContainer.style.borderRadius = "4px"
        setTimeout(() => { starsContainer.style.outline = "none" }, 2000)
      }
      return
    }

    const submitBtn = form.querySelector("[data-star-rating-target='submit']")
    if (submitBtn) {
      submitBtn.disabled = true
      submitBtn.textContent = "Envoi..."
    }

    try {
      // Envoie le formulaire en AJAX avec le header JSON pour obtenir une réponse JSON
      const response = await fetch(form.action, {
        method:  "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
          "Accept":       "application/json"
        },
        body: new FormData(form)
      })

      const data = await response.json()

      if (response.ok && data.success) {
        // ✅ Succès : remplace la card par un message "Noté"
        card.innerHTML = `
          <div style="display:flex; align-items:center; justify-content:center; gap:0.5rem; padding:0.75rem; color:#1EDD88;">
            <span style="font-size:1rem;">★</span>
            <span style="font-size:0.85rem; font-weight:600;">Avis envoyé !</span>
          </div>
        `
        // Met à jour le compteur dans l'en-tête
        this.updatePendingCount()
        // Vérifie si tous les avis ont été soumis pour fermer automatiquement
        this.checkIfAllReviewed()
      } else {
        // ❌ Erreur métier (ex: fenêtre 7j dépassée) — affiche le message
        const errorMsg = data.error || "Une erreur est survenue."
        card.querySelector("[data-star-rating-target='submit']") &&
          (card.querySelector("[data-star-rating-target='submit']").disabled = false)
        this.showCardError(card, errorMsg)
      }
    } catch (err) {
      // Erreur réseau
      this.showCardError(card, "Erreur de connexion, réessayez.")
      if (submitBtn) {
        submitBtn.disabled = false
        submitBtn.textContent = "Envoyer mon avis"
      }
    }
  }

  // Ferme la modal — appelé par le bouton "Plus tard" et la croix
  dismiss() {
    const modal = bootstrap.Modal.getInstance(this.element)
    if (modal) modal.hide()
  }

  // Sélectionne un candidat pour le vote "homme du match"
  // Appelé par data-action="click->review-modal#selectVoteCandidate" sur chaque bouton-joueur
  selectVoteCandidate(event) {
    const matchId  = event.currentTarget.dataset.matchId
    const playerId = event.currentTarget.dataset.playerId

    // Réinitialise le style de tous les boutons de ce match
    const allBtns = this.element.querySelectorAll(`.vote-candidate-btn[data-match-id="${matchId}"]`)
    allBtns.forEach(btn => {
      btn.style.background   = "rgba(255,255,255,0.05)"
      btn.style.borderColor  = "rgba(255,255,255,0.1)"
      btn.style.color        = "rgba(255,255,255,0.65)"
    })

    // Marque le bouton cliqué comme sélectionné (couleur ambre = homme du match)
    event.currentTarget.style.background  = "rgba(245,158,11,0.15)"
    event.currentTarget.style.borderColor = "rgba(245,158,11,0.45)"
    event.currentTarget.style.color       = "#f59e0b"

    // Active le bouton de vote et stocke le candidat sélectionné dans son dataset
    const voteBtn = this.element.querySelector(`[data-action*="submitVote"][data-match-id="${matchId}"]`)
    if (voteBtn) {
      voteBtn.disabled          = false
      voteBtn.style.opacity     = "1"
      voteBtn.dataset.votedForId = playerId
    }
  }

  // Soumet le vote "homme du match" en AJAX
  // Appelé par data-action="click->review-modal#submitVote" sur le bouton de vote
  async submitVote(event) {
    const btn        = event.currentTarget
    const matchId    = btn.dataset.matchId
    const votedForId = btn.dataset.votedForId

    // Sécurité : ne fait rien si aucun candidat n'est sélectionné
    if (!votedForId) return

    btn.disabled     = true
    btn.textContent  = "Envoi..."

    try {
      // POST /matches/:match_id/match_votes avec le candidat sélectionné
      const response = await fetch(`/matches/${matchId}/match_votes`, {
        method:  "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
          "Accept":       "application/json",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ match_vote: { voted_for_id: votedForId } })
      })

      const data = await response.json()

      if (response.ok && data.success) {
        // ✅ Succès : remplace la section vote par un message de confirmation
        const section = document.getElementById(`vote-section-${matchId}`)
        if (section) {
          section.innerHTML = `
            <div style="display:flex; align-items:center; justify-content:center; gap:0.5rem; padding:0.5rem; color:#f59e0b;">
              <span>🏆</span>
              <span style="font-size:0.85rem; font-weight:600;">Vote enregistré !</span>
            </div>
          `
        }
        // Vérifie si tout est fait pour fermer la modal automatiquement
        this.checkIfAllReviewed()
      } else {
        // ❌ Erreur : réactive le bouton et affiche le message
        btn.disabled    = false
        btn.textContent = "Voter pour l'homme du match"
        btn.style.opacity = "1"
        const errorMsg  = data.error || "Une erreur est survenue."
        const section   = document.getElementById(`vote-section-${matchId}`)
        if (section) this.showCardError(section, errorMsg)
      }
    } catch (err) {
      // Erreur réseau
      btn.disabled    = false
      btn.textContent = "Voter pour l'homme du match"
      btn.style.opacity = "1"
    }
  }

  // Met à jour le compteur "encore N joueurs à noter" dans l'en-tête de la modal
  // Appelé après chaque soumission d'avis réussie
  updatePendingCount() {
    const label = this.element.querySelector("[data-pending-label]")
    if (!label) return

    // Compte les formulaires de review encore actifs (= joueurs pas encore notés)
    const remaining = this.element.querySelectorAll(".review-card form").length

    if (remaining === 0) {
      // Tous les joueurs ont été notés — message final
      label.textContent = "Tous les joueurs ont été notés ✓"
      label.style.color = "#1EDD88"
    } else {
      label.textContent = `encore ${remaining} ${remaining > 1 ? "joueurs" : "joueur"} à noter`
    }
  }

  // Ferme la modal si toutes les cards ont été notées ET tous les votes soumis
  checkIfAllReviewed() {
    // Formulaires de review encore actifs
    const activeForms  = this.element.querySelectorAll(".review-card form")
    // Boutons de vote encore disponibles (non soumis)
    const pendingVotes = this.element.querySelectorAll(".vote-candidate-btn")

    if (activeForms.length === 0 && pendingVotes.length === 0) {
      setTimeout(() => this.dismiss(), 1200)
    }
  }

  // Affiche un message d'erreur dans la card
  showCardError(card, message) {
    // Retire l'erreur précédente si elle existe
    const prev = card.querySelector(".review-error")
    if (prev) prev.remove()

    const errorDiv = document.createElement("div")
    errorDiv.className = "review-error"
    errorDiv.style.cssText = "font-size:0.75rem; color:#ff6b6b; margin-top:0.4rem; text-align:center;"
    errorDiv.textContent = message
    card.appendChild(errorDiv)
  }
}
