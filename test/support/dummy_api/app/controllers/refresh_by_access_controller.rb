class RefreshByAccessController < ApplicationController
  include ActionController::Cookies
  before_action :authorize_refresh_by_access_request!

  def create
    session = JWTSessions::Session.new(payload: payload, refresh_by_access_allowed: true)
    tokens = session.refresh_by_access(found_token)
    cookies[JWTSessions.access_cookie] = tokens[:access]

    render json: { csrf: tokens[:csrf] }
  end
end
