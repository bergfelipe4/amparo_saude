import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "empty"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replaceAll("__INDEX__", Date.now())
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.emptyTargets.forEach((el) => el.classList.add("hidden"))
  }

  remove(event) {
    event.preventDefault()
    event.currentTarget.closest("[data-dynamic-fields-target='row']").remove()
  }
}
