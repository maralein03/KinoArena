module Admin
  class ShowtimesController < BaseController
    before_action :set_showtime, only: [ :edit, :update, :destroy ]
    before_action :load_form_collections, only: [ :new, :create, :edit, :update ]

    def index
      authorize Showtime
      @showtimes = policy_scope(Showtime).includes(:movie, :auditorium).order(:start_time)
    end

    def new
      @showtime = Showtime.new
      authorize @showtime
    end

    def create
      @showtime = Showtime.new(showtime_params)
      authorize @showtime

      if @showtime.save
        log_activity("showtime_created", target: @showtime, description: @showtime.label)
        redirect_to admin_showtimes_path, notice: "Vorstellung wurde angelegt."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @showtime
    end

    def update
      authorize @showtime

      if @showtime.update(showtime_params)
        log_activity("showtime_updated", target: @showtime, description: @showtime.label)
        redirect_to admin_showtimes_path, notice: "Vorstellung wurde aktualisiert."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @showtime
      label = @showtime.label
      @showtime.destroy!

      log_activity("showtime_deleted", description: label)
      redirect_to admin_showtimes_path, notice: "Vorstellung wurde geloescht."
    end

    private

    def set_showtime
      @showtime = Showtime.find(params[:id])
    end

    def load_form_collections
      @movies = Movie.order(:title)
      @auditoria = Auditorium.order(:name)
    end

    def showtime_params
      params.require(:showtime).permit(*policy(@showtime || Showtime.new).permitted_attributes)
    end
  end
end
