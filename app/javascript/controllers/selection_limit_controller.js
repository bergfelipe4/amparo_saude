import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "count"]
  static values = { limit: Number }

  connect() { this.refresh() }
  refresh() {
    const selected = this.checkboxTargets.filter((checkbox) => checkbox.checked)
    this.checkboxTargets.forEach((checkbox) => { checkbox.disabled = selected.length >= this.limitValue && !checkbox.checked })
    if (this.hasCountTarget) this.countTarget.textContent = `${selected.length}/${this.limitValue}`
  }
}
