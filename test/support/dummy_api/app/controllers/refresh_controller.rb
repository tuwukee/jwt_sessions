class RefreshController < ApplicationController
  authenticate_refresh_request!

  def create
  end
end
