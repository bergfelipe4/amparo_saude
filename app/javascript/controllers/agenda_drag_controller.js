import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["block", "column"]
  static values = {
    moveUrlTemplate: String,
    date: String,
    dayStart: Number,
    rowMin: Number,
    rowHeight: Number,
    snapMin: Number,
  }

  connect() {
    this.blockTargets.forEach((block) => {
      block.addEventListener("dragstart", this.dragStart.bind(this))
      block.addEventListener("dragend", this.dragEnd.bind(this))
    })
    this.columnTargets.forEach((column) => {
      column.addEventListener("dragover", this.dragOver.bind(this))
      column.addEventListener("dragenter", this.dragEnter.bind(this))
      column.addEventListener("dragleave", this.dragLeave.bind(this))
      column.addEventListener("drop", this.drop.bind(this))
    })
  }

  dragStart(event) {
    this.dragged = event.currentTarget
    this.originalColumn = this.dragged.parentElement
    this.originalTop = this.dragged.style.top
    this.dragged.classList.add("dragging")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.dragged.dataset.id)
  }

  dragEnd() {
    this.dragged?.classList.remove("dragging")
    this.columnTargets.forEach((c) => c.classList.remove("drag-over"))
    this.dragged = null
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
  }

  dragEnter(event) {
    event.currentTarget.classList.add("drag-over")
  }

  dragLeave(event) {
    event.currentTarget.classList.remove("drag-over")
  }

  drop(event) {
    event.preventDefault()
    const column = event.currentTarget
    column.classList.remove("drag-over")
    if (!this.dragged) return

    const block = this.dragged
    const originalColumn = this.originalColumn
    const originalTop = this.originalTop

    const rect = column.getBoundingClientRect()
    const y = event.clientY - rect.top
    const rawMinutes = (y / this.rowHeightValue) * this.rowMinValue
    const snapped = Math.round(rawMinutes / this.snapMinValue) * this.snapMinValue
    const totalMinutes = Math.max(0, this.dayStartValue + snapped)
    const hh = String(Math.floor(totalMinutes / 60)).padStart(2, "0")
    const mm = String(totalMinutes % 60).padStart(2, "0")
    const startsAt = `${this.dateValue}T${hh}:${mm}:00`

    const professionalId = column.dataset.professionalId
    const appointmentId = block.dataset.id
    const durationMin = parseInt(block.dataset.durationMin, 10)

    const top = ((totalMinutes - this.dayStartValue) / this.rowMinValue) * this.rowHeightValue + 2
    const height = (durationMin / this.rowMinValue) * this.rowHeightValue - 4

    column.appendChild(block)
    block.style.top = `${top}px`
    block.style.height = `${height}px`

    const url = this.moveUrlTemplateValue.replace(":id", appointmentId)
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        Accept: "application/json",
      },
      body: JSON.stringify({ professional_id: professionalId, starts_at: startsAt }),
    })
      .then((response) => response.json().then((data) => ({ ok: response.ok, data })))
      .then(({ ok, data }) => {
        if (ok && data.ok) {
          this.refreshModalIfShowing(appointmentId)
          return
        }
        originalColumn.appendChild(block)
        block.style.top = originalTop
        alert(data.error || "Não foi possível mover a consulta.")
      })
      .catch(() => {
        originalColumn.appendChild(block)
        block.style.top = originalTop
        alert("Não foi possível mover a consulta. Verifique sua conexão.")
      })
  }

  // Se o modal estiver aberto mostrando exatamente essa consulta, recarrega o
  // conteúdo dele pra refletir o novo médico/horário sem precisar fechar e abrir de novo.
  // Usa frame.reload() (não frame.src = mesmaURL) porque o Turbo ignora reatribuições
  // de src pro mesmo valor — reload() força a nova busca mesmo com a URL inalterada.
  // O id da consulta fica marcado num elemento DENTRO do frame (o Turbo só troca o
  // conteúdo do <turbo-frame>, nunca os atributos da própria tag).
  refreshModalIfShowing(appointmentId) {
    const modal = document.getElementById("modal")
    const backdrop = modal?.querySelector("[data-appointment-id]")
    if (!backdrop || backdrop.dataset.appointmentId !== appointmentId) return
    modal.reload()
  }
}
