import { Controller } from "@hotwired/stimulus"

// Tela de conexão do WhatsApp: dispara a sessão, mostra o QR Code e faz
// polling do status até conectar (ou dar erro) — sem depender de Turbo Stream
// porque o estado vem de um serviço externo (WPPConnect), não do banco local.
export default class extends Controller {
  static targets = [
    "qrFrame", "qrImage", "spinner", "checkIcon", "badge", "badgeLabel", "helpText",
    "actions", "retryButton", "disconnectButton",
    "stepGenerate", "stepScan", "stepDone", "lineOne", "lineTwo"
  ]
  static values = { statusUrl: String, startUrl: String, initialState: String }

  POLL_MS = 2500
  LIVE_STATES = ["nao_iniciado", "iniciando", "aguardando_qr", "conectando"]

  connect() {
    if (this.initialStateValue === "conectado") {
      this.poll()
    } else {
      this.start()
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  async start() {
    this.retryButtonTarget.classList.add("hidden")
    this.setBadge("iniciando", "Gerando QR Code…")
    try {
      await fetch(this.startUrlValue, { method: "POST", headers: this.headers() })
    } catch (_e) {
      // segue pro polling mesmo assim — o status vai refletir o problema
    }
    this.poll()
  }

  retry() {
    this.start()
  }

  async poll() {
    clearTimeout(this.timeout)
    try {
      const response = await fetch(this.statusUrlValue, { headers: this.headers() })
      const data = await response.json()
      this.render(data)
      if (this.LIVE_STATES.includes(data.state)) {
        this.timeout = setTimeout(() => this.poll(), this.POLL_MS)
      }
    } catch (_e) {
      this.timeout = setTimeout(() => this.poll(), this.POLL_MS)
    }
  }

  render(data) {
    this.setBadge(data.state, data.label)
    this.updateSteps(data.state)

    if (data.state === "conectado") {
      this.showConnected()
    } else if (data.qrcode) {
      this.showQrCode(data.qrcode)
    } else if (["erro", "expirado", "desconectado"].includes(data.state)) {
      this.showError(data.label)
    } else {
      this.showSpinner()
    }
  }

  setBadge(state, label) {
    this.badgeTarget.className = `wpp-status-badge state-${state}`
    this.badgeTarget.querySelector(".wpp-status-dot")?.classList.toggle("is-live", this.LIVE_STATES.includes(state))
    this.badgeLabelTarget.textContent = label
  }

  updateSteps(state) {
    const generateDone = state !== "nao_iniciado" && state !== "iniciando"
    const scanActive = ["aguardando_qr", "conectando"].includes(state)
    const scanDone = state === "conectado"

    this.stepGenerateTarget.classList.toggle("is-active", !generateDone)
    this.stepGenerateTarget.classList.toggle("is-done", generateDone)
    this.lineOneTarget.classList.toggle("is-done", generateDone)

    this.stepScanTarget.classList.toggle("is-active", scanActive)
    this.stepScanTarget.classList.toggle("is-done", scanDone)
    this.lineTwoTarget.classList.toggle("is-done", scanDone)

    this.stepDoneTarget.classList.toggle("is-active", scanDone)
    this.stepDoneTarget.classList.toggle("is-done", scanDone)
  }

  showSpinner() {
    this.spinnerTarget.classList.remove("hidden")
    this.qrImageTarget.classList.add("hidden")
    this.checkIconTarget.classList.add("hidden")
    this.qrFrameTarget.classList.remove("is-waiting")
    this.retryButtonTarget.classList.add("hidden")
    this.disconnectButtonTarget.classList.add("hidden")
  }

  showQrCode(dataUrl) {
    this.spinnerTarget.classList.add("hidden")
    this.checkIconTarget.classList.add("hidden")
    this.qrImageTarget.src = dataUrl
    this.qrImageTarget.classList.remove("hidden")
    this.qrFrameTarget.classList.add("is-waiting")
    this.retryButtonTarget.classList.add("hidden")
    this.disconnectButtonTarget.classList.add("hidden")
    this.helpTextTarget.textContent = "Abra o WhatsApp no celular da clínica → Configurações → Dispositivos conectados → Conectar dispositivo, e escaneie o código acima."
  }

  showConnected() {
    this.spinnerTarget.classList.add("hidden")
    this.qrImageTarget.classList.add("hidden")
    this.checkIconTarget.classList.remove("hidden")
    this.qrFrameTarget.classList.remove("is-waiting")
    this.retryButtonTarget.classList.add("hidden")
    this.disconnectButtonTarget.classList.remove("hidden")
    this.helpTextTarget.textContent = "Conectado! A secretária de IA já pode conversar pelo WhatsApp da clínica."
  }

  showError(label) {
    this.spinnerTarget.classList.add("hidden")
    this.qrImageTarget.classList.add("hidden")
    this.checkIconTarget.classList.add("hidden")
    this.qrFrameTarget.classList.remove("is-waiting")
    this.retryButtonTarget.classList.remove("hidden")
    this.disconnectButtonTarget.classList.add("hidden")
    this.helpTextTarget.textContent = label
  }

  headers() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    return token ? { "X-CSRF-Token": token, "Accept": "application/json" } : { "Accept": "application/json" }
  }
}
