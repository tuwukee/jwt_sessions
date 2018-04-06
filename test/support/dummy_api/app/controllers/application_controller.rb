class ApplicationController < ActionController::API
  include JWTSessions::RailsAuthorization
end
