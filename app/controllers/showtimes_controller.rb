class ShowtimesController < ApplicationController
  def index
    @showtimes = Showtime.upcoming
    @movies = Movie.where(id: @showtimes.select(:movie_id)).order(:title)
    @showtime_counts = @showtimes.group(:movie_id).count
  end

  def show
    @showtime = Showtime.includes(:movie, :auditorium).find(params[:id])
    SeatHold.release_expired!

    @seats = @showtime.auditorium.seats.ordered
    @booked_seat_ids = @showtime.bookings.pluck(:seat_id).to_set
    @holds_by_seat_id = @showtime.seat_holds.active.index_by(&:seat_id)
    @rows = @seats.group_by(&:row)
    @seat_numbers = @seats.map(&:number).uniq.sort
  end
end
