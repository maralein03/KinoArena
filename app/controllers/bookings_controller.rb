class BookingsController < ApplicationController
  before_action :require_user

  def index
    @bookings = policy_scope(Booking)
                  .includes(showtime: [ :movie, :auditorium ], seat: :auditorium)
                  .recent_first
  end

  def show
    @booking = Booking.find(params[:id])
    authorize @booking
  end

  def create
    @showtime = Showtime.find(params[:showtime_id])
    seat_ids = Array(params[:seat_ids]).reject(&:blank?)

    if seat_ids.empty?
      redirect_to showtime_path(@showtime), alert: "Bitte waehle mindestens einen Sitzplatz aus."
      return
    end

    bookings = build_bookings(@showtime, seat_ids)
    authorize bookings.first

    Booking.transaction { bookings.each(&:save!) }

    log_activity("booking_created", target: @showtime,
                 description: "#{bookings.size} Ticket(s) gebucht: #{bookings.map { |b| b.seat.label }.join(', ')}")

    redirect_to bookings_path, notice: "Buchung erfolgreich. Deine Tickets sind bereit."
  rescue ActiveRecord::RecordNotUnique
    # NFA-1: Unique-Index auf [showtime_id, seat_id] hat eine Doppelbuchung verhindert
    log_activity("booking_conflict", target: @showtime, description: "Doppelbuchung verhindert (DB-Constraint)")
    redirect_to showtime_path(@showtime),
                alert: "Dieser Sitzplatz wurde gerade von jemand anderem gebucht. Bitte waehle einen anderen Platz."
  rescue ActiveRecord::RecordInvalid => e
    log_activity("booking_failed", target: @showtime, description: e.record.errors.full_messages.to_sentence)
    redirect_to showtime_path(@showtime),
                alert: "Buchung nicht moeglich: #{e.record.errors.full_messages.to_sentence}"
  end

  def destroy
    @booking = Booking.find(params[:id])
    authorize @booking
    showtime = @booking.showtime
    seat_label = @booking.seat.label
    @booking.destroy!

    log_activity("booking_cancelled", target: showtime, description: "Ticket #{seat_label} storniert")
    redirect_to bookings_path, notice: "Ticket wurde storniert."
  end

  private

  def build_bookings(showtime, seat_ids)
    seats = showtime.auditorium.seats.where(id: seat_ids)

    if seats.size != seat_ids.size
      raise ActiveRecord::RecordInvalid, Booking.new.tap { |b|
        b.errors.add(:seat, "gehoert nicht zum Saal dieser Vorstellung")
      }
    end

    seats.map { |seat| current_user.bookings.build(showtime: showtime, seat: seat) }
  end
end
