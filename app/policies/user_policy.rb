# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    owner_or_admin?
  end

  def update?
    owner_or_admin?
  end

  def destroy?
    return false if user.blank?
    return true if record == user

    admin? && !last_admin?
  end

  def change_role?
    admin? && record != user
  end

  def permitted_attributes
    base = [ :name, :email_address, :password, :password_confirmation ]
    admin? ? base + [ :admin ] : base
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      user.admin? ? scope.all : scope.where(id: user.id)
    end
  end

  private

  def admin?
    user.present? && user.admin?
  end

  def owner_or_admin?
    user.present? && (record == user || user.admin?)
  end

  def last_admin?
    record.admin? && User.admins.count <= 1
  end
end
