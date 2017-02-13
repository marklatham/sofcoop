Rails.application.routes.draw do
  
  devise_for :users, path: '',
             path_names: {sign_up: 'register', sign_in: 'login', sign_out: 'logout'},
             controllers: {confirmations: 'users/confirmations',
                               passwords: 'users/passwords',
                           registrations: 'users/registrations',
                                sessions: 'users/sessions',
                                 unlocks: 'users/unlocks'}

  devise_scope :user do
    get '/change_password' => 'users/registrations#change_password'
    get '/create_username' => 'users/registrations#create_username'
  end

  root 'visitors#index'
  
  resources :users
  
end
