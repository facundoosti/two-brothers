class UserPolicy < ApplicationPolicy
  # Cualquier usuario autenticado puede ver su propio perfil
  def me?     = true
  def index?  = admin?
  def update? = admin?
end
