import { Controller } from "@hotwired/stimulus"

// Zeigt Auswahl und Summe im Saalplan ohne Seitenreload.
export default class extends Controller {
    static targets = ["seat", "summary", "total", "count", "submit"]
    static values = { price: Number }

    connect() {
        this.update()
    }

    update() {
        const selected = this.seatTargets.filter((seat) => seat.checked)
        const total = selected.length * this.priceValue

        this.summaryTarget.innerHTML = selected.length
            ? selected
                .map((seat) => `<span class="ka-chip">${seat.dataset.label}</span>`)
                .join(" ")
            : '<span class="text-sm text-slate-500">Noch keine Plätze gewählt</span>'

        this.countTarget.textContent = `${selected.length} × ${this.formatPrice(this.priceValue)}`
        this.totalTarget.textContent = this.formatPrice(total)
        this.submitTarget.disabled = selected.length === 0
        this.submitTarget.textContent = selected.length
            ? `${selected.length} Ticket${selected.length > 1 ? "s" : ""} buchen`
            : "Bitte Sitzplätze wählen"
    }

    formatPrice(value) {
        return `CHF ${value.toFixed(2)}`
    }
}
