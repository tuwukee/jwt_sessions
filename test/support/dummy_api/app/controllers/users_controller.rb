class UsersController < ApplicationController
  before_action :authenticate_access_request!

  def show
  end
end
