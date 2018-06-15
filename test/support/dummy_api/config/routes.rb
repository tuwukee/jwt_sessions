Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post :login, to: 'login#create'
  post :login_with_cookies, to: 'login_with_cookies#create'
  post :refresh, to: 'refresh#create'
  post :refresh_by_access, to: 'refresh_by_access#create'

  resources :users, only: [:show, :create]
end
