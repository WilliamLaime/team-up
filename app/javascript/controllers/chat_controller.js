// Stimulus controller pour le chat de match
// Rôles :
//   1. Auto-scroll vers le bas à chaque nouveau message
//   2. Appliquer le style "chat-message--mine" sur les messages de l'utilisateur connecté
//   3. Envoyer le message avec la touche Entrée
//   4. Gérer l'indicateur "X est en train d'écrire..." via ActionCable

import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  // Valeurs lues depuis les data-attributes HTML
  static values = {
    currentUserId:  Number, // data-chat-current-user-id-value
    matchId:        Number, // data-chat-match-id-value (présent uniquement sur le chat match)
    markReadUrl:    String, // data-chat-mark-read-url-value (présent uniquement sur le chat privé)
    conversationId: Number  // data-chat-conversation-id-value (présent uniquement sur le chat privé)
  }

  // Cibles HTML surveillées par ce controller
  static targets = ["messages", "input", "form", "submit", "typing", "typingName"]

  // Appelé quand le controller est connecté au DOM
  connect() {
    this.applyMineStyles()
    this.scrollToBottom()
    this.observeNewMessages()
    // Pour le chat privé uniquement : retire le dot si la modale est ouverte
    this.observeSidebarForUnreadDot()

    // Pour le chat privé : s'abonner immédiatement au canal de frappe
    // (le chat match s'abonne lui dans onModalOpen, mais c'est un autre contexte)
    if (this.hasConversationIdValue && !this.hasMatchIdValue) {
      this.subscribeToPrivateTypingChannel()
    }

    // Scroll supplémentaire après le chargement complet du turbo-frame
    // Couvre le cas où connect() se déclenche avant que le DOM soit totalement stable
    this._frameLoadHandler = () => this.scrollToBottom()
    this.element.addEventListener("turbo:frame-load", this._frameLoadHandler)

    // Scroll quand l'utilisateur ouvre la modale Bootstrap alors qu'une conversation
    // est déjà chargée dans le frame (connect() ne se re-déclenche pas dans ce cas)
    this._modalShownHandler = () => this.scrollToBottom()
    const modal = document.getElementById("global-chat-modal")
    if (modal) modal.addEventListener("shown.bs.modal", this._modalShownHandler)
  }

  // Appelé quand le controller est déconnecté (navigation, etc.)
  disconnect() {
    if (this.observer) this.observer.disconnect()
    if (this._sidebarObserver) this._sidebarObserver.disconnect()
    if (this.subscription) this.subscription.unsubscribe()
    this.clearTypingTimeout()
    // Nettoyage du listener turbo:frame-load
    if (this._frameLoadHandler) {
      this.element.removeEventListener("turbo:frame-load", this._frameLoadHandler)
    }
    // Nettoyage du listener shown.bs.modal
    if (this._modalShownHandler) {
      const modal = document.getElementById("global-chat-modal")
      if (modal) modal.removeEventListener("shown.bs.modal", this._modalShownHandler)
    }
  }

  // ── ActionCable : s'abonner au canal de frappe ──────────────────────────────

  // Appelé quand le modal Bootstrap est affiché (événement shown.bs.modal)
  onModalOpen() {
    this.scrollToBottom()
    if (this.hasInputTarget) this.inputTarget.focus()

    // On s'abonne au canal de frappe seulement quand le modal est ouvert
    // pour éviter des connexions inutiles si l'utilisateur ne l'ouvre jamais
    if (!this.subscription && this.hasMatchIdValue) {
      this.subscribeToTypingChannel()
    }
  }

  // Crée l'abonnement ActionCable au canal MatchChatChannel
  subscribeToTypingChannel() {
    const consumer = createConsumer()

    this.subscription = consumer.subscriptions.create(
      { channel: "MatchChatChannel", match_id: this.matchIdValue },
      {
        // Quand on reçoit un signal de frappe d'un autre utilisateur
        received: (data) => {
          // On n'affiche pas l'indicateur si c'est notre propre frappe
          if (data.user_id !== this.currentUserIdValue) {
            this.showTypingIndicator(data.user_name)
          }
        }
      }
    )
  }

  // Crée l'abonnement ActionCable au canal PrivateChatChannel
  // Appelé dans connect() quand on est dans un chat privé (conversationIdValue présent)
  subscribeToPrivateTypingChannel() {
    const consumer = createConsumer()

    this.subscription = consumer.subscriptions.create(
      { channel: "PrivateChatChannel", conversation_id: this.conversationIdValue },
      {
        // Quand on reçoit un signal de frappe de l'autre utilisateur
        received: (data) => {
          // On n'affiche pas l'indicateur pour sa propre frappe
          if (data.user_id !== this.currentUserIdValue) {
            this.showTypingIndicator(data.user_name)
          }
        }
      }
    )
  }

  // Appelé à chaque frappe dans le champ de saisie (data-action="input->chat#onTyping")
  onTyping() {
    // Envoie le signal "typing" au serveur via ActionCable
    if (this.subscription) {
      this.subscription.perform("typing")
    }
  }

  // ── Indicateur de frappe ───────────────────────────────────────────────────

  showTypingIndicator(userName) {
    if (!this.hasTypingTarget) return

    // Met à jour le nom affiché et rend l'indicateur visible
    if (this.hasTypingNameTarget) this.typingNameTarget.textContent = userName
    this.typingTarget.style.display = "flex"

    // Réinitialise le timer : cache l'indicateur après 3 secondes sans signal
    this.clearTypingTimeout()
    this.typingTimeout = setTimeout(() => {
      this.typingTarget.style.display = "none"
    }, 3000)
  }

  // Cache immédiatement l'indicateur de frappe et annule le timer
  hideTypingIndicator() {
    this.clearTypingTimeout()
    if (this.hasTypingTarget) {
      this.typingTarget.style.display = "none"
    }
  }

  clearTypingTimeout() {
    if (this.typingTimeout) clearTimeout(this.typingTimeout)
  }

  // ── Scroll et styles ───────────────────────────────────────────────────────

  // Observe les nouveaux messages ajoutés par Turbo Stream
  observeNewMessages() {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            this.applyMineStyleTo(node)
            // Supprime le message "Brise la glace" au 1er message envoyé
            this.removeEmptyState()
            // Cache immédiatement l'indicateur "est en train d'écrire" dès qu'un message arrive
            this.hideTypingIndicator()

            // Si on est dans un chat privé (markReadUrl présent) et que le
            // nouveau message vient de l'autre utilisateur → marquer comme lu
            // UNIQUEMENT si la modale est actuellement ouverte (visible par l'utilisateur)
            // Si la modale est fermée, on ne marque pas comme lu pour que le voyant vert apparaisse
            if (this.hasMarkReadUrlValue) {
              const senderId = parseInt(node.dataset.userId, 10)
              const modal = document.getElementById("global-chat-modal")
              const isModalOpen = modal && modal.classList.contains("show")
              if (senderId !== this.currentUserIdValue && isModalOpen) {
                this.markConversationRead()
              }
            }
          }
        })
      })
      this.scrollToBottom()
    })

    if (this.hasMessagesTarget) {
      this.observer.observe(this.messagesTarget, { childList: true })
    }
  }

  // Observe la sidebar pour détecter si un voyant non-lu apparaît sur CETTE conversation
  // pendant que la modale est ouverte (race condition : le broadcast sidebar peut arriver
  // après le broadcast message, donc après que markConversationRead ait déjà été appelé)
  observeSidebarForUnreadDot() {
    if (!this.hasMarkReadUrlValue || !this.hasConversationIdValue) return

    const sidebarList = document.getElementById("private-chat-sidebar-list")
    if (!sidebarList) return

    this._sidebarObserver = new MutationObserver(() => {
      const modal = document.getElementById("global-chat-modal")
      const isModalOpen = modal && modal.classList.contains("show")
      if (!isModalOpen) return

      // Cherche l'item de CETTE conversation dans la sidebar
      const item = document.getElementById(`private-convo-${this.conversationIdValue}`)
      if (item && item.querySelector(".sticky-chat-unread-dot")) {
        // Le dot est apparu alors qu'on est en train de lire → on marque comme lu
        this.markConversationRead()
      }
    })

    // Observe le conteneur de la liste (subtree pour détecter les remplacements d'items)
    this._sidebarObserver.observe(sidebarList, { subtree: true, childList: true })
  }

  // Appelle le serveur pour marquer la conversation privée comme lue
  // Le serveur broadcast ensuite l'item sidebar sans voyant vert
  markConversationRead() {
    fetch(this.markReadUrlValue, {
      method: "PATCH",
      headers: {
        // Token CSRF obligatoire pour les requêtes non-GET en Rails
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        "Accept": "text/html"
      }
    })
  }

  // Supprime le message vide "Brise la glace" s'il est encore présent
  removeEmptyState() {
    const emptyState = document.getElementById("chat-empty")
    if (emptyState) emptyState.remove()
  }

  // Applique le style "mine" sur tous les messages existants
  applyMineStyles() {
    if (!this.hasMessagesTarget) return
    this.messagesTarget.querySelectorAll(".chat-message").forEach((msg) => {
      this.applyMineStyleTo(msg)
    })
  }

  // Applique le style "mine" sur un seul message si l'auteur correspond
  // Le CSS --mine gère déjà le masquage de l'avatar et du nom — pas besoin de JS pour ça
  applyMineStyleTo(element) {
    const userId = parseInt(element.dataset.userId, 10)
    if (userId === this.currentUserIdValue) {
      element.classList.remove("chat-message--theirs")
      element.classList.add("chat-message--mine")
    }
  }

  // Scroll vers le bas de la zone de messages
  // requestAnimationFrame garantit que le navigateur a fini de peindre le contenu
  // avant de calculer scrollHeight — sinon le scroll peut se déclencher trop tôt
  // (ex: quand le turbo-frame vient d'être injecté ou quand la modale anime)
  scrollToBottom() {
    if (!this.hasMessagesTarget) return
    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    })
  }

  // ── Raccourci clavier ──────────────────────────────────────────────────────

  // Envoie le message avec Entrée (sans Shift)
  // Bloqué si le champ est vide ou ne contient que des espaces
  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      // Ne soumet pas si le champ est vide
      if (this.hasInputTarget && this.inputTarget.value.trim() === "") return
      this.element.querySelector("form").requestSubmit()
    }
  }
}
