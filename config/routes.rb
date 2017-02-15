Rails.application.routes.draw do

  root 'visitors#index'
  
  # http://guides.rubyonrails.org/routing.html#generating-paths-and-urls-from-code
  get '/@:username', to: 'users#show' # Naming this path didn't work, so created a helper.
  get '/@:username/:slug', to: 'pages#show'

  devise_for :users, path: '',
             path_names: {sign_up: 'register', sign_in: 'login', sign_out: 'logout'},
             controllers: {confirmations: 'users/confirmations',
                               passwords: 'users/passwords',
                           registrations: 'users/registrations',
                                sessions: 'users/sessions',
                                 unlocks: 'users/unlocks'}

  devise_scope :user do
    get '/change_password', to: 'users/registrations#change_password'
    get '/create_username', to: 'users/registrations#create_username'
  end

  resources :users
  resources :pages
  
end
