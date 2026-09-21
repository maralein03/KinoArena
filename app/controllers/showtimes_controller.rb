class ShowtimesController < ApplicationController
  def index
    @showtimes = Showtime.includes(:movie, :auditorium).all
  end

  def show
    @showtime = Showtime.find(params[:id])
    @seats = @showtime.auditorium.seats.order(:row, :number)
  end
end