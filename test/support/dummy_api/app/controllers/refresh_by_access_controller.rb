# frozen_string_literal: true

class RefreshByAccessController < ApplicationController
  include ActionController::Cookies
  before_action :authorize_refresh_by_access_request!

  def create
    session = JWTSessions::Session.new(payload: safe_payload, refresh_by_access_allowed: true)
    tokens = session.refresh_by_access(found_token) do
      # notify the support
      raise JWTSessions::Errors::Unauthorized, 'Malicious activity detected'
    end
    cookies[JWTSessions.access_cookie] = { value: tokens[:access], httponly: true }

    render json: { csrf: tokens[:csrf] }
  end
end
