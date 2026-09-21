module Admin
  class MoviesController < BaseController
    before_action :set_movie, only: [ :edit, :update, :destroy ]

    def index
      authorize Movie
      @movies = policy_scope(Movie).order(:title)
    end

    def new
      @movie = Movie.new
      authorize @movie
    end

    def create
      @movie = Movie.new(movie_params)
      authorize @movie

      if @movie.save
        log_activity("movie_created", target: @movie, description: @movie.title)
        redirect_to admin_movies_path, notice: "Film \"#{@movie.title}\" wurde angelegt."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @movie
    end

    def update
      authorize @movie

      if @movie.update(movie_params)
        log_activity("movie_updated", target: @movie, description: @movie.title)
        redirect_to admin_movies_path, notice: "Film \"#{@movie.title}\" wurde aktualisiert."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @movie
      title = @movie.title

      if @movie.destroy
        log_activity("movie_deleted", description: title)
        redirect_to admin_movies_path, notice: "Film \"#{title}\" wurde geloescht."
      else
        redirect_to admin_movies_path, alert: @movie.errors.full_messages.to_sentence
      end
    end

    private

    def set_movie
      @movie = Movie.find(params[:id])
    end

    def movie_params
      params.require(:movie).permit(*policy(@movie || Movie.new).permitted_attributes)
    end
  end
end
