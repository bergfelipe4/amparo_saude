import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop"]

  open() {
    this.panelTarget.classList.add("is-open")
    this.backdropTarget.classList.remove("hidden")
  }

  close() {
    this.panelTarget.classList.remove("is-open")
    this.backdropTarget.classList.add("hidden")
  }
}
