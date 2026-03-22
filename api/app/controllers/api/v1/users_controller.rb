module Api
  module V1
    class UsersController < BaseController
      # GET /api/v1/me
      def me
        authorize current_user, :me?
        render json: UserBlueprint.render_as_hash(current_user)
      end

      # GET /api/v1/users
      def index
        authorize User
        scope = User.all
        scope = scope.where(role: params[:role]) if params[:role].present?
        scope = scope.where("name ILIKE ? OR email ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?

        @pagy, users = pagy(:offset, scope)
        render json: {
          data: UserBlueprint.render_as_hash(users),
          pagy: pagy_meta(@pagy)
        }
      end

      # PATCH /api/v1/users/:id
      def update
        user = User.find(params[:id])
        authorize user
        if user.update(user_params)
          render json: UserBlueprint.render_as_hash(user)
        else
          render_error(user.errors.full_messages.join(", "))
        end
      end

      private

      def user_params
        params.require(:user).permit(:role, :status)
      end
    end
  end
end
