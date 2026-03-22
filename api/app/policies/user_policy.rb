class UserPolicy < ApplicationPolicy
  # Cualquier usuario autenticado puede ver y actualizar su propio perfil
  def me?          = true
  def update_me?   = true
  def index?       = admin?
  def update?      = admin?
end
