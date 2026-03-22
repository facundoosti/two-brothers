module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      user  = User.find_by(api_token: token) if token
      reject_unauthorized_connection unless user
      user
    end
  end
end
