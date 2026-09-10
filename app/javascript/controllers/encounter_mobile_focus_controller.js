import { Controller } from "@hotwired/stimulus"

// No celular, após escolher uma consulta na lista, leva a pessoa direto ao
// resumo do paciente. Em telas maiores a navegação continua sem rolagem.
export default class extends Controller {
  static values = { target: { type: Boolean, default: false } }

  focus(event) {
    if (!window.matchMedia("(max-width: 639.98px)").matches) return

    const url = new URL(event.currentTarget.href)
    url.searchParams.set("focus_appointment", "1")
    event.currentTarget.href = url.toString()
  }

  connect() {
    if (!this.targetValue) return
    const url = new URL(window.location.href)
    if (url.searchParams.get("focus_appointment") !== "1") return
    if (!window.matchMedia("(max-width: 639.98px)").matches) return

    requestAnimationFrame(() => {
      this.element.scrollIntoView({ behavior: "smooth", block: "start" })
      url.searchParams.delete("focus_appointment")
      history.replaceState(null, "", `${url.pathname}${url.search}${url.hash}`)
    })
  }
}
