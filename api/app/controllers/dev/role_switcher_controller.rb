module Dev
  class RoleSwitcherController < ApplicationController
    ALLOWED_ROLES = %w[customer delivery admin].freeze

    # PATCH /dev/switch_role
    def switch_role
      role = params[:role]

      unless ALLOWED_ROLES.include?(role)
        return render json: { error: "Rol inválido. Opciones: #{ALLOWED_ROLES.join(', ')}" }, status: :unprocessable_entity
      end

      current_user.update!(role: role)
      render json: UserBlueprint.render_as_hash(current_user)
    end

    # POST /dev/switch_user
    def switch_user
      user = User.find_by!(uid: params[:uid])
      render json: UserBlueprint.render_as_hash(user).merge(token: user.api_token)
    end
  end
end
