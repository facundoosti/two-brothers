class SettingPolicy < ApplicationPolicy
  def show?   = admin?
  def update? = admin?
end
