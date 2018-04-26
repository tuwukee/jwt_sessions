# frozen_string_literal: true

class LoginWithCookiesController < ApplicationController
  include ActionController::Cookies

  def create
    user = User.find_by!(email: params[:email])
    if user.authenticate(params[:password])

      payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload)
      tokens = session.login
      cookies[JWTSessions.access_cookie] = tokens[:access]
      cookies[JWTSessions.refresh_cookie] = tokens[:refresh]

      render json: { csrf: tokens[:csrf] }
    else
      render json: 'Invalid email or password', status: :unauthorized
    end
  end
end
