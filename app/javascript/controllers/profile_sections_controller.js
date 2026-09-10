import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: { type: String, default: "visao-geral" } }

  connect() {
    const section = new URL(window.location.href).searchParams.get("section")
    this.activate(this.hasSection(section) ? section : this.activeValue, false)
  }

  select(event) {
    event.preventDefault()
    this.activate(event.currentTarget.dataset.section, true)
  }

  activate(section, updateUrl) {
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.section === section
      tab.classList.toggle("is-active", active)
      tab.setAttribute("aria-selected", active)
    })
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.section !== section })

    if (updateUrl) {
      const url = new URL(window.location.href)
      url.searchParams.set("section", section)
      history.replaceState(null, "", `${url.pathname}${url.search}${url.hash}`)
    }
  }

  hasSection(section) { return this.panelTargets.some((panel) => panel.dataset.section === section) }
}
