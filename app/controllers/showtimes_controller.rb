class ShowtimesController < ApplicationController
  def index
    @showtimes = Showtime.includes(:movie, :auditorium).upcoming
  end

  def show
    @showtime = Showtime.includes(:movie, :auditorium).find(params[:id])
    @seats = @showtime.auditorium.seats.ordered
    @booked_seat_ids = @showtime.bookings.pluck(:seat_id).to_set
    @rows = @seats.group_by(&:row)
  end
end
