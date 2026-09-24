class SeatHoldsController < ApplicationController
  before_action :require_user
  before_action :set_showtime

  # Reserviert einen Sitzplatz fuer 5 Minuten (FA-Opt-3).
  def create
    seat = @showtime.auditorium.seats.find(params[:seat_id])
    hold = SeatHold.hold!(showtime: @showtime, seat: seat, user: current_user)

    SeatBroadcast.seat_changed(@showtime, seat)
    render json: { expires_at: hold.expires_at.iso8601, remaining_seconds: hold.remaining_seconds }
  rescue ActiveRecord::RecordNotUnique
    render json: { error: "Dieser Platz wurde gerade von jemand anderem reserviert." }, status: :conflict
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def destroy
    hold = @showtime.seat_holds.find_by(seat_id: params[:id], user_id: current_user.id)
    return head :not_found if hold.nil?

    seat = hold.seat
    hold.destroy
    SeatBroadcast.seat_changed(@showtime, seat)
    head :no_content
  end

  private

  def set_showtime
    @showtime = Showtime.find(params[:showtime_id])
    SeatHold.release_expired!
  end
end
