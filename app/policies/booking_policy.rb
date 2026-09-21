# frozen_string_literal: true

class BookingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (record.user_id == user.id || user.admin?)
  end

  def create?
    user.present?
  end

  def destroy?
    show? && record.showtime.start_time > Time.current
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      user.admin? ? scope.all : scope.where(user_id: user.id)
    end
  end
end
