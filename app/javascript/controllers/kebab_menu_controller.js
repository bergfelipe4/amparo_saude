import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.outsideClick = this.outsideClick.bind(this)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.menuTarget.classList.contains("hidden") ? this.open() : this.close()
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.element.classList.add("is-open")
    document.addEventListener("click", this.outsideClick)
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.element.classList.remove("is-open")
    document.removeEventListener("click", this.outsideClick)
  }

  outsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
  }
}
