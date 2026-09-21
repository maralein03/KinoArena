# KinoArena – Smart Cinema Booking & Management System

Modul 223 (Multiuser-Applikationen objektorientiert realisieren)
Autorin: Mara Spichiger · Klasse 24-223-E

---

## 1. Problemstellung

In kleineren und unabhängigen Kinos laufen Spielplanverwaltung und Sitzplatzreservierung
oft über starre Altsysteme oder manuelle Prozesse. Für Besucherinnen und Besucher ist
dadurch unklar, welche Plätze tatsächlich noch frei sind. Bei beliebten Vorstellungen
führen gleichzeitige Zugriffe zweier Kunden auf denselben Platz ohne saubere
Systemunterstützung zu Doppelbuchungen.

KinoArena automatisiert den Buchungsprozess vollständig und stellt sicher, dass
Parallelzugriffe fachlich korrekt und ohne Dateninkonsistenzen abgewickelt werden.

## 2. Funktionsumfang

### Kunde
- Konto erstellen, anmelden, abmelden
- Filmprogramm und Spielzeiten einsehen
- Freie Sitzplätze im virtuellen Saalplan auswählen und verbindlich buchen
- Tickets inklusive QR-Code abrufen und stornieren
- Eigenes Profil bearbeiten

### Administrator
- Filme verwalten (CRUD)
- Vorstellungen terminieren und Sälen zuweisen
- Benutzer und Rollen verwalten
- Aktivitätsprotokoll einsehen und filtern

---

## 3. Datenmodell

```mermaid
erDiagram
    USER ||--o{ BOOKING : "bucht"
    USER ||--o{ ACTIVITY_LOG : "verursacht"
    MOVIE ||--o{ SHOWTIME : "wird gezeigt in"
    AUDITORIUM ||--o{ SHOWTIME : "beherbergt"
    AUDITORIUM ||--o{ SEAT : "enthält"
    SHOWTIME ||--o{ BOOKING : "wird gebucht als"
    SEAT ||--o{ BOOKING : "wird belegt durch"

    USER {
        int id PK
        string email_address UK
        string password_digest
        string name
        boolean admin
    }
    MOVIE {
        int id PK
        string title
        text description
        int duration_minutes
        string poster_url
        int lock_version "Optimistic Locking"
    }
    AUDITORIUM {
        int id PK
        string name UK
        int total_seats
    }
    SEAT {
        int id PK
        int auditorium_id FK
        string row
        int number
    }
    SHOWTIME {
        int id PK
        int movie_id FK
        int auditorium_id FK
        datetime start_time
        decimal price
        int lock_version "Optimistic Locking"
    }
    BOOKING {
        int id PK
        int user_id FK
        int showtime_id FK
        int seat_id FK
        string qr_code_token UK
        decimal total_price
    }
    ACTIVITY_LOG {
        int id PK
        int user_id FK "nullable"
        string action
        string target_type
        int target_id
        string description
        string ip_address
    }
```

Zentrale Regel: **`bookings` besitzt einen zusammengesetzten Unique-Index auf
`[showtime_id, seat_id]`** – ein Sitzplatz kann pro Vorstellung nur einmal existieren.

---

## 4. Concurrency und Datenintegrität

### Stufe 1 – Unique-Index gegen Doppelbuchungen

Zwei Kunden wählen gleichzeitig den letzten freien Platz A1 derselben Vorstellung.

Die Datenbank lässt nur eine der beiden Transaktionen durch. Die zweite scheitert mit
`ActiveRecord::RecordNotUnique` und wird im Controller abgefangen:

```ruby
# app/controllers/bookings_controller.rb
Booking.transaction { bookings.each(&:save!) }
rescue ActiveRecord::RecordNotUnique
  redirect_to showtime_path(@showtime),
              alert: "Dieser Sitzplatz wurde gerade von jemand anderem gebucht. …"
```

Die Validierung im Modell fängt den Normalfall ab, der Datenbank-Index den echten
Wettlauf – eine Validierung allein genügt bei parallelen Prozessen nicht.

### Stufe 2 – Optimistic Locking im Admin-Bereich

Zwei Administratoren bearbeiten gleichzeitig dieselbe Vorstellung. `movies` und
`showtimes` besitzen eine Spalte `lock_version`; das Formular sendet sie als Hidden
Field mit. Beim Speichern veralteter Daten wirft Rails `ActiveRecord::StaleObjectError`:

```ruby
# app/controllers/admin/base_controller.rb
rescue_from ActiveRecord::StaleObjectError, with: :handle_stale_object
```

Der zweite Administrator erhält HTTP 409 und den Hinweis, dass die Daten zwischenzeitlich
geändert wurden – statt fremde Änderungen stillschweigend zu überschreiben.

---

## 5. Architektur

| Schicht | Ort | Aufgabe |
|---|---|---|
| Modelle | `app/models/` | Fachlogik, Validierungen, Assoziationen |
| Policies | `app/policies/` | Berechtigungen (Pundit), zentral und testbar |
| Controller | `app/controllers/` | Ablaufsteuerung, Fehlerbehandlung |
| Views | `app/views/` | Darstellung, Tailwind-Komponenten |
| Stimulus | `app/javascript/controllers/` | Saalplan-Auswahl ohne Seitenreload |

Der Admin-Bereich liegt im Namespace `Admin::` mit eigener `BaseController`, die
`require_admin` erzwingt.

### Berechtigungskonzept

Alle Zugriffe laufen über Pundit-Policies. `ApplicationPolicy` verweigert
standardmässig alles (Deny by default), Unterklassen erlauben gezielt.

Rechte-Eskalation wird über `permitted_attributes` verhindert: Nur Administratoren
dürfen das Attribut `admin` überhaupt übermitteln.

```ruby
# app/policies/user_policy.rb
def permitted_attributes
  base = [ :name, :email_address, :password, :password_confirmation ]
  admin? ? base + [ :admin ] : base
end
```

---

## 6. Technologiestack

| Bereich | Technologie |
|---|---|
| Framework | Ruby on Rails 8.1 |
| Sprache | Ruby 4.0 |
| Datenbank | SQLite3 |
| Autorisierung | Pundit |
| Passwörter | bcrypt (`has_secure_password`) |
| Frontend | Tailwind CSS 4, Hotwire (Turbo + Stimulus) |
| QR-Codes | rqrcode |
| Tests | Minitest, Capybara |

> **Hinweis zum `json`-Gem:** Im Gemfile ist `json` auf `~> 2.21` festgenagelt.
> Version 3.x ist mit ActiveSupport 8.1 inkompatibel (`JSON.parse` akzeptiert keine
> positionalen Optionen mehr), wodurch jede angemeldete Sitzung mit einem
> `ArgumentError` abbricht.

---

## 7. Setup

Voraussetzungen: Ruby 4.0, Bundler, SQLite3

```bash
git clone git@github.com:maralein03/KinoArena.git
cd KinoArena

bin/setup                 # Abhängigkeiten, Datenbank, Seeds
bin/dev                   # Server auf http://localhost:3000
```

Datenbank einzeln aufsetzen:

```bash
bin/rails db:prepare
bin/rails db:seed
```

### Demo-Zugänge

| Rolle | E-Mail | Passwort |
|---|---|---|
| Administrator | `admin@kinoarena.ch` | `adminadmin` |
| Kundin A | `anna@example.com` | `annaanna` |
| Kunde B | `ben@example.com` | `benbenben` |

Die beiden Kundenkonten dienen dazu, die Doppelbuchungssperre (NFA-1) in zwei
getrennten Browser-Sitzungen vorzuführen.

---

## 8. Tests

```bash
bin/rails test              # Modell-, Controller- und Integrationstests
bin/rails test:system       # Systemtests (End-to-End)
bin/rails test:all          # alles zusammen
```

Systemtests laufen standardmässig mit dem `rack_test`-Treiber und benötigen keinen
installierten Browser. Für JavaScript-Prüfungen mit Headless Chrome:

```bash
SYSTEM_TEST_DRIVER=selenium bin/rails test:system
```

### Abgedeckte Szenarien

| Bereich | Datei |
|---|---|
| Doppelbuchung (Unique-Index) | `test/models/booking_test.rb` |
| Optimistic Locking | `test/models/showtime_test.rb`, `test/controllers/admin/movies_controller_test.rb` |
| Zugriffskontrolle | `test/controllers/users_controller_test.rb`, `test/system/admin_area_test.rb` |
| Buchungsablauf End-to-End | `test/system/booking_flow_test.rb` |
| Authentifizierung | `test/system/authentication_test.rb` |
| Fehlerbehandlung (404) | `test/integration/error_handling_test.rb` |

### Qualitätswerkzeuge

```bash
bin/rubocop                 # Code-Konventionen
bin/brakeman                # Sicherheitsanalyse
bin/bundler-audit check     # Bekannte Schwachstellen in Gems
```

---

## 9. Abdeckung der Anforderungen

| Anforderung | Umsetzung |
|---|---|
| FA-1 Authentifizierung | `SessionsController`, `RegistrationsController` |
| FA-2 Film- & Vorstellungsübersicht | `ShowtimesController#index`, `MoviesController#show` |
| FA-3 Sitzplatzauswahl & Buchung | `ShowtimesController#show`, `BookingsController#create` |
| FA-4 Meine Buchungen | `BookingsController#index` / `#show` |
| FA-5 Filmverwaltung | `Admin::MoviesController` |
| FA-6 Spielplanverwaltung | `Admin::ShowtimesController` |
| FA-Opt-1 QR-Code | `BookingsHelper#qr_code_svg` |
| NFA-1 Keine Doppelbuchungen | Unique-Index `[showtime_id, seat_id]` |
| NFA-2 Optimistic Locking | `lock_version` auf `movies` und `showtimes` |
| NFA-4 Access Control | Pundit-Policies, `require_admin` |
| NFA-5 Fehlerbehandlung | Formulare mit erhaltenen Eingaben, 404-Seite, Flash-Meldungen |

### Nicht umgesetzt

| Anforderung | Begründung |
|---|---|
| FA-Opt-2 Zahlungs-Checkout | Als optional deklariert; kein echter Zahlungsanbieter im Schulkontext |
| FA-Opt-3 Temporäre Reservierung | Als optional deklariert; erfordert Hintergrundjobs zum Freigeben abgelaufener Reservationen |

---

## 10. Aktivitätsprotokoll

Jede sicherheits- und fachrelevante Aktion wird in `activity_logs` festgehalten:
Anmeldung, fehlgeschlagener Anmeldeversuch, Abmeldung, Registrierung,
Profiländerung, Kontolöschung, Buchung, Buchungskonflikt, Stornierung,
CRUD-Operationen auf Filme und Vorstellungen sowie Locking-Konflikte.

Das Protokoll ist unter `/admin/activity_logs` nach Aktion und Benutzer filterbar.
Fehler beim Schreiben eines Eintrags brechen den Fachablauf bewusst nicht ab.
