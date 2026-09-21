module Admin
  class AuditoriaController < BaseController
    before_action :set_auditorium, only: [ :edit, :update, :destroy ]

    def index
      authorize Auditorium
      @auditoria = policy_scope(Auditorium).order(:name)
    end

    def new
      @auditorium = Auditorium.new(row_count: 8, seats_per_row: 12)
      authorize @auditorium
    end

    def create
      @auditorium = Auditorium.new(auditorium_params)
      authorize @auditorium

      if @auditorium.save
        log_activity("auditorium_created", target: @auditorium,
                     description: "#{@auditorium.name} mit #{@auditorium.total_seats} Plätzen")
        redirect_to admin_auditoria_path, notice: "Saal \"#{@auditorium.name}\" wurde mit " \
                                                  "#{@auditorium.total_seats} Sitzplätzen angelegt."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @auditorium
    end

    # Der Saalplan bleibt unveraendert, damit bestehende Buchungen gueltig bleiben.
    def update
      authorize @auditorium

      if @auditorium.update(auditorium_params)
        log_activity("auditorium_updated", target: @auditorium, description: @auditorium.name)
        redirect_to admin_auditoria_path, notice: "Saal wurde umbenannt."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @auditorium
      name = @auditorium.name

      if @auditorium.destroy
        log_activity("auditorium_deleted", description: name)
        redirect_to admin_auditoria_path, notice: "Saal \"#{name}\" wurde gelöscht."
      else
        redirect_to admin_auditoria_path,
                    alert: "Saal \"#{name}\" kann nicht gelöscht werden, solange Vorstellungen geplant sind."
      end
    end

    private

    def set_auditorium
      @auditorium = Auditorium.find(params[:id])
    end

    def auditorium_params
      params.require(:auditorium).permit(*policy(@auditorium || Auditorium.new).permitted_attributes)
    end
  end
end
