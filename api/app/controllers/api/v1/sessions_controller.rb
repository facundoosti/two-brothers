module Api
  module V1
    class SessionsController < BaseController
      # DELETE /api/v1/session
      def destroy
        current_user.regenerate_api_token!
        head :no_content
      end
    end
  end
end
