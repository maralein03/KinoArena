import { Controller } from "@hotwired/stimulus"

const FREE_CLASSES = [
    "bg-slate-600", "ring-1", "ring-inset", "ring-white/20",
    "hover:bg-slate-500", "hover:ring-brand-400", "cursor-pointer"
]
const MINE_CLASSES = ["bg-brand-500", "ring-1", "ring-inset", "ring-brand-400", "cursor-pointer"]
const OTHER_CLASSES = ["bg-gold-400", "ring-1", "ring-inset", "ring-gold-400", "cursor-not-allowed"]
const ALL_CLASSES = [...new Set([...FREE_CLASSES, ...MINE_CLASSES, ...OTHER_CLASSES])]

// Saalplan mit temporaerer Reservierung (FA-Opt-3) und Live-Updates via Turbo Stream.
export default class extends Controller {
    static targets = ["seat", "summary", "total", "count", "submit", "timer", "countdown", "notice"]
    static values = { price: Number, holdUrl: String, loggedIn: Boolean }

    connect() {
        this.currentUserId = document.querySelector('meta[name="current-user-id"]')?.content || ""
        this.seatTargets.forEach((seat) => this.renderSeat(seat))
        this.update()
        this.ticker = setInterval(() => this.tick(), 1000)
    }

    disconnect() {
        clearInterval(this.ticker)
    }

    // Wird auch aufgerufen, wenn Turbo einen Sitzplatz per Broadcast ersetzt.
    seatTargetConnected(seat) {
        this.renderSeat(seat)
        this.update()
    }

    seatTargetDisconnected() {
        this.update()
    }

    async toggle(event) {
        if (!this.loggedInValue) return

        const seat = event.currentTarget.closest("[data-seat-id]")
        const state = this.stateOf(seat)

        if (state === "other") return
        if (state === "mine") {
            await this.release(seat)
        } else {
            await this.hold(seat)
        }
    }

    async hold(seat) {
        const response = await this.request("POST", this.holdUrlValue, { seat_id: seat.dataset.seatId })

        if (response.ok) {
            const data = await response.json()
            seat.dataset.holderId = this.currentUserId
            seat.dataset.expiresAt = data.expires_at
            this.hideNotice()
        } else {
            const data = await response.json().catch(() => ({}))
            this.showNotice(data.error || "Dieser Platz ist nicht mehr verfügbar.")
        }

        this.renderSeat(seat)
        this.update()
    }

    async release(seat) {
        await this.request("DELETE", `${this.holdUrlValue}/${seat.dataset.seatId}`)

        seat.dataset.holderId = ""
        seat.dataset.expiresAt = ""
        this.renderSeat(seat)
        this.update()
    }

    request(method, url, body) {
        return fetch(url, {
            method,
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
            },
            body: body ? JSON.stringify(body) : undefined
        })
    }

    stateOf(seat) {
        if (seat.dataset.booked === "true") return "booked"

        const holder = seat.dataset.holderId
        if (!holder) return "free"
        return holder === this.currentUserId ? "mine" : "other"
    }

    renderSeat(seat) {
        const button = seat.querySelector("button")
        if (!button) return

        const checkbox = seat.querySelector('input[type="checkbox"]')
        const lock = button.querySelector("svg")
        const state = this.stateOf(seat)

        button.classList.remove(...ALL_CLASSES)

        if (state === "mine") {
            button.classList.add(...MINE_CLASSES)
            button.title = `Platz ${seat.dataset.seatLabel} – deine Reservierung`
            lock.classList.add("hidden")
        } else if (state === "other") {
            button.classList.add(...OTHER_CLASSES)
            button.title = `Platz ${seat.dataset.seatLabel} wird gerade von einer anderen Person gebucht`
            lock.classList.remove("hidden")
        } else {
            button.classList.add(...FREE_CLASSES)
            button.title = `Platz ${seat.dataset.seatLabel} ist frei`
            lock.classList.add("hidden")
        }

        button.disabled = !this.loggedInValue || state === "other"
        if (checkbox) checkbox.checked = state === "mine"
    }

    mySeats() {
        return this.seatTargets.filter((seat) => this.stateOf(seat) === "mine")
    }

    update() {
        const selected = this.mySeats()
        const total = selected.length * this.priceValue

        this.summaryTarget.innerHTML = selected.length
            ? selected.map((seat) => `<span class="ka-chip">${seat.dataset.seatLabel}</span>`).join(" ")
            : '<span class="text-sm text-slate-500">Noch keine Plätze gewählt</span>'

        this.countTarget.textContent = `${selected.length} × ${this.formatPrice(this.priceValue)}`
        this.totalTarget.textContent = this.formatPrice(total)
        this.submitTarget.disabled = selected.length === 0
        this.submitTarget.textContent = selected.length
            ? `${selected.length} Ticket${selected.length > 1 ? "s" : ""} buchen`
            : "Bitte Sitzplätze wählen"

        this.timerTarget.classList.toggle("hidden", selected.length === 0)
        this.timerTarget.classList.toggle("flex", selected.length > 0)
    }

    tick() {
        const selected = this.mySeats()
        if (selected.length === 0) return

        const earliest = selected
            .map((seat) => new Date(seat.dataset.expiresAt).getTime())
            .sort((a, b) => a - b)[0]

        const remaining = Math.max(0, Math.round((earliest - Date.now()) / 1000))
        this.countdownTarget.textContent = this.formatDuration(remaining)

        if (remaining === 0) {
            selected.forEach((seat) => this.release(seat))
            this.showNotice("Deine Reservierung ist abgelaufen. Bitte wähle die Plätze erneut.")
        }
    }

    showNotice(message) {
        this.noticeTarget.textContent = message
        this.noticeTarget.classList.remove("hidden")
    }

    hideNotice() {
        this.noticeTarget.classList.add("hidden")
    }

    formatPrice(value) {
        return `CHF ${value.toFixed(2)}`
    }

    formatDuration(seconds) {
        const minutes = Math.floor(seconds / 60)
        return `${String(minutes).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`
    }
}
