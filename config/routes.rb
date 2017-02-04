Rails.application.routes.draw do
  
  devise_for :users, path: '', path_names: {sign_up: 'register', sign_in: 'login', sign_out: 'logout'},
             controllers: {registrations: 'users/registrations', sessions: 'users/sessions'}

  root 'visitors#index'
  
end
