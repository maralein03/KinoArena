class ShowtimesController < ApplicationController
  def index
    @showtimes = Showtime.upcoming
    @movies = Movie.where(id: @showtimes.select(:movie_id)).order(:title)
    @showtime_counts = @showtimes.group(:movie_id).count
  end

  def show
    @showtime = Showtime.includes(:movie, :auditorium).find(params[:id])
    @seats = @showtime.auditorium.seats.ordered
    @booked_seat_ids = @showtime.bookings.pluck(:seat_id).to_set
    @rows = @seats.group_by(&:row)
    @seat_numbers = @seats.map(&:number).uniq.sort
  end
end
