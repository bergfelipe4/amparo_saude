import { Controller } from "@hotwired/stimulus"

// Mantém o painel de atendimento compacto, sem perder nenhuma função.
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: { type: String, default: "prontuario" } }

  connect() {
    const fromHash = window.location.hash.replace("#", "")
    this.activate(this.hasSection(fromHash) ? fromHash : this.activeValue, false)
  }

  select(event) {
    event.preventDefault()
    this.activate(event.currentTarget.dataset.section, true)
  }

  activate(section, updateHash) {
    if (!this.hasSection(section)) section = this.activeValue
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.section === section
      tab.classList.toggle("is-active", active)
      tab.setAttribute("aria-selected", active)
      tab.tabIndex = active ? 0 : -1
    })
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.section !== section })
    if (updateHash) history.replaceState(null, "", `#${section}`)
  }

  hasSection(section) { return this.panelTargets.some((panel) => panel.dataset.section === section) }
}
