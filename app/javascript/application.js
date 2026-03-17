// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import * as bootstrap from "bootstrap"

// Initialise les tooltips Bootstrap après chaque navigation Turbo
// (turbo:load se déclenche aussi au premier chargement de page)
document.addEventListener("turbo:load", () => {
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
    new bootstrap.Tooltip(el)
  })
})
