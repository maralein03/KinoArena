import { Controller } from "@hotwired/stimulus"

const PROCESSING_DELAY = 1600

// Fuehrt durch Bestaetigung, Zahlungsauswahl und simulierte Zahlung (FA-Opt-2).
export default class extends Controller {
    static targets = ["step", "processing", "processingHint", "method", "payButton", "form", "timer"]
    static values = { expiresAt: String }

    connect() {
        this.showStep("confirm")
        this.selectMethod()
        if (this.expiresAtValue) {
            this.tick()
            this.ticker = setInterval(() => this.tick(), 1000)
        }
    }

    disconnect() {
        clearInterval(this.ticker)
    }

    toPayment() {
        this.showStep("payment")
    }

    toConfirm() {
        this.showStep("confirm")
    }

    showStep(name) {
        this.stepTargets.forEach((step) => step.classList.toggle("hidden", step.dataset.step !== name))
    }

    selectedMethod() {
        return this.methodTargets.find((input) => input.checked)
    }

    selectMethod() {
        const method = this.selectedMethod()
        if (method) this.payButtonTarget.textContent = `mit ${method.dataset.label} bezahlen`
    }

    // Zeigt die Verarbeitung an und sendet das Formular erst danach ab.
    pay(event) {
        event.preventDefault()

        const method = this.selectedMethod()
        this.stepTargets.forEach((step) => step.classList.add("hidden"))
        this.processingTarget.classList.remove("hidden")
        if (method) this.processingHintTarget.textContent = `${method.dataset.label} wird bestätigt`

        setTimeout(() => this.formTarget.requestSubmit(), PROCESSING_DELAY)
    }

    tick() {
        const remaining = Math.max(0, Math.round((new Date(this.expiresAtValue).getTime() - Date.now()) / 1000))
        const minutes = String(Math.floor(remaining / 60)).padStart(2, "0")
        const seconds = String(remaining % 60).padStart(2, "0")

        this.timerTarget.classList.remove("hidden")
        this.timerTarget.textContent = `Plätze reserviert für ${minutes}:${seconds}`

        if (remaining === 0) {
            clearInterval(this.ticker)
            this.timerTarget.textContent = "Reservierung abgelaufen"
        }
    }
}
