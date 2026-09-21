# frozen_string_literal: true

class ShowtimePolicy < AdminPolicy
  def index?
    true
  end

  def show?
    true
  end

  def permitted_attributes
    [ :movie_id, :auditorium_id, :start_time, :price, :lock_version ]
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
