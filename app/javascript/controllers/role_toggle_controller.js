import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["medicoFields"]

  toggle(event) {
    const isMedico = event.target.value === "medico"
    this.medicoFieldsTargets.forEach((el) => el.classList.toggle("hidden", !isMedico))
  }
}
