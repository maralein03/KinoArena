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
    SeatHold.release_expired!
    seat_ids = Array(params[:seat_ids]).reject(&:blank?)

    if seat_ids.empty?
      redirect_to showtime_path(@showtime), alert: "Bitte waehle mindestens einen Sitzplatz aus."
      return
    end

    bookings = nil
    seats = nil

    # NFA-1 Stufe 4: Pessimistic Lock auf der Vorstellung. Pruefung der
    # Sitzplaetze und Insert laufen dadurch als eine ununterbrechbare Einheit;
    # eine parallele Buchung wartet, statt auf veralteten Daten zu entscheiden.
    @showtime.with_lock do
      bookings = build_bookings(@showtime, seat_ids)
      authorize bookings.first
      seats = bookings.map(&:seat)

      bookings.each(&:save!)
      @showtime.seat_holds.where(seat_id: seats.map(&:id)).delete_all
    end

    SeatBroadcast.seats_changed(@showtime, seats)
    log_activity("booking_created", target: @showtime,
                 description: "#{bookings.size} Ticket(s) via #{bookings.first.payment_method_label} gebucht: " \
                              "#{seats.map(&:label).join(', ')}")

    redirect_to bookings_path, notice: "Zahlung erfolgreich. Deine Tickets sind bereit."
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
    seat = @booking.seat
    @booking.destroy!

    SeatBroadcast.seat_changed(showtime, seat)
    log_activity("booking_cancelled", target: showtime, description: "Ticket #{seat.label} storniert")
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

    reserved_by_others = showtime.seat_holds.active
                                 .where(seat_id: seats.map(&:id))
                                 .where.not(user_id: current_user.id)
                                 .includes(:seat)

    if reserved_by_others.any?
      raise ActiveRecord::RecordInvalid, Booking.new.tap { |b|
        b.errors.add(:seat, "#{reserved_by_others.map { |h| h.seat.label }.join(', ')} " \
                            "wird gerade von einer anderen Person gebucht")
      }
    end

    seats.map do |seat|
      current_user.bookings.build(showtime: showtime, seat: seat, payment_method: payment_method)
    end
  end

  def payment_method
    Booking::PAYMENT_METHODS.key?(params[:payment_method]) ? params[:payment_method] : nil
  end
end
