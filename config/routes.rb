Rails.application.routes.draw do
  
  devise_for :users, path: '',
             path_names: {sign_up: 'register', sign_in: 'login', sign_out: 'logout'},
             controllers: {confirmations: 'users/confirmations',
                               passwords: 'users/passwords',
                           registrations: 'users/registrations',
                                sessions: 'users/sessions',
                                 unlocks: 'users/unlocks'}

  root 'visitors#index'
  
end
