import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["existingFields", "newFields"]

  toggle(event) {
    const isNew = event.target.value === "new"
    this.newFieldsTarget.classList.toggle("hidden", !isNew)
    this.existingFieldsTarget.classList.toggle("hidden", isNew)
  }
}
