# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authorize_access_request!

  def create
    user = User.new(user_params)
    if user.save
      render json: { current_user: current_user.to_json, user: user.to_json }
    else
      render json: { errors: user.errors.full_messages }
    end
  end

  def show
    user = User.find(params[:id])
    render json: { current_user: current_user.to_json, user: user.to_json }
  end

  private

  def user_params
    params.require(:user).permit(:email, :password)
  end
end
