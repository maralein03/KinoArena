# frozen_string_literal: true

class AuditoriumPolicy < AdminPolicy
  def permitted_attributes
    if record.is_a?(Auditorium) && record.persisted?
      [ :name ]
    else
      [ :name, :row_count, :seats_per_row ]
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.admin? ? scope.all : scope.none
    end
  end
end
