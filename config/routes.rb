Rails.application.routes.draw do

  root 'visitors#index'
  
  # http://guides.rubyonrails.org/routing.html#generating-paths-and-urls-from-code
  get    '/@:username/:slug',        to: 'pages#show',         as: :page
  get    '/@:username/:slug/edit',   to: 'pages#edit',         as: :edit_page
  delete '/@:username/:slug/delete', to: 'pages#destroy',      as: :delete_page
  
  resources :pages, except: [:show, :edit, :destroy]
  
  get    '/@:username',              to: 'users#show',         as: :username
  
  resources :users, only:   [:show, :index]

  devise_for :users, path: '',
             path_names: {sign_up: 'register', sign_in: 'login', sign_out: 'logout'},
             controllers: {confirmations: 'users/confirmations',
                               passwords: 'users/passwords',
                           registrations: 'users/registrations',
                                sessions: 'users/sessions',
                                 unlocks: 'users/unlocks'}

  devise_scope :user do
    get '/change_password', to: 'users/registrations#change_password', as: :change_password
    get '/create_username', to: 'users/registrations#create_username', as: :create_username
  end
  
end
