class CheckoutsController < ApplicationController
  before_action :require_user

  # FA-Opt-2: Bestaetigung und Zahlungsauswahl vor der eigentlichen Buchung.
  def show
    @showtime = Showtime.includes(:movie, :auditorium).find(params[:showtime_id])
    SeatHold.release_expired!

    @seats = @showtime.auditorium.seats.where(id: Array(params[:seat_ids])).ordered
    if @seats.empty?
      redirect_to showtime_path(@showtime), alert: "Bitte wähle zuerst mindestens einen Sitzplatz aus."
      return
    end

    @booking_fee = 0
    @total = @showtime.price * @seats.size + @booking_fee
    @hold_expires_at = @showtime.seat_holds.active
                                .where(seat_id: @seats.map(&:id), user_id: current_user.id)
                                .minimum(:expires_at)
  end
end
