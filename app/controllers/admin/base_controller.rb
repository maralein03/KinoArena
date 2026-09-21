module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    layout "application"

    rescue_from ActiveRecord::StaleObjectError, with: :handle_stale_object

    private

    # NFA-2: zweiter Admin wird gewarnt statt fremde Aenderungen zu ueberschreiben
    def handle_stale_object
      flash.now[:alert] = "Die Daten wurden zwischenzeitlich von jemand anderem geaendert. " \
                          "Bitte pruefe die aktuellen Werte und speichere erneut."
      log_activity("stale_object_conflict", description: "Optimistic-Locking-Konflikt in #{controller_name}")
      render :edit, status: :conflict
    end
  end
end
