Rails.application.routes.draw do
  
  devise_for :users, controllers: { sessions: 'users/sessions' }, path: '', path_names: {sign_up: 'register', sign_in: 'login', sign_out: 'logout'}
  
  root 'visitors#index'
  
end
