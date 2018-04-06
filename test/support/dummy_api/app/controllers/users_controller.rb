# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_access_request!

  def show
    user = User.find(params[:id])
    current_user = User.find(payload['user_id'])
    render json: { current_user: current_user.to_json, user: user.to_json }
  end
end
