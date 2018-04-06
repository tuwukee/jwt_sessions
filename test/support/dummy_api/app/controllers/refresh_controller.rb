class RefreshController < ApplicationController
  before_action :authenticate_refresh_request!

  def create
    session = JWTSessions::Session.new(payload: payload)
    render json: session.refresh(found_token)
  end
end
