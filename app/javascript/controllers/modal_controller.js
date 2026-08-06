import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    this.element.remove()
  }

  backdropClick(event) {
    if (event.target === this.element) this.close()
  }

  escape(event) {
    if (event.key === "Escape") this.close()
  }
}
