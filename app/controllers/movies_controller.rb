class MoviesController < ApplicationController
  def show
    @movie = Movie.find(params[:id])
    authorize @movie
    @showtimes_by_date = @movie.showtimes.includes(:auditorium).upcoming.group_by { |s| s.start_time.to_date }
  end
end
