import { Controller } from "@hotwired/stimulus"

// Auto-Fade Controller for Voice Command Rails
// Automatically fades out and removes messages after a configurable delay
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 }  // Default 5 seconds
  }

  connect() {
    // Start the fade-out timer
    this.timeout = setTimeout(() => {
      this.fadeOut()
    }, this.delayValue)
  }

  disconnect() {
    // Clear timeout if element is removed before fading
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  fadeOut() {
    // Add fade-out class or set opacity directly
    this.element.style.opacity = "0"

    // Remove element after transition completes (500ms as defined in CSS)
    this.removeTimeout = setTimeout(() => {
      this.element.remove()
    }, 500)
  }

  // Allow manual dismissal (can be called by click events)
  dismiss() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    this.fadeOut()
  }
}
