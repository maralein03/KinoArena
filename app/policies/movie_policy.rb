# frozen_string_literal: true

class MoviePolicy < AdminPolicy
  def index?
    true
  end

  def show?
    true
  end

  def permitted_attributes
    [ :title, :description, :duration_minutes, :lock_version ]
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
