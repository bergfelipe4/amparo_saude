import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const root = document.documentElement
    const next = root.getAttribute("data-theme") === "dark" ? "light" : "dark"
    root.setAttribute("data-theme", next)
    localStorage.setItem("theme", next)
  }
}
