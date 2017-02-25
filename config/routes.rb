Rails.application.routes.draw do

  root 'visitors#index'
  
  ### PAGES: #######################
  
  get    '/@:username/:slug',        to: 'pages#show',         as: :page
  get    '/@:username/:slug/edit',   to: 'pages#edit',         as: :edit_page
  delete '/@:username/:slug/delete', to: 'pages#destroy',      as: :delete_page
  
  resources :pages, except: [:show, :edit, :destroy]
  
  ### USERS: #######################
  
  get    '/@:username',              to: 'users#show',         as: :user
  get    '/users',                   to: 'users#index',        as: :users

  devise_for :users, path: '',
             path_names:  {      sign_up: 'register',
                                 sign_in: 'login',
                                sign_out: 'logout',
                                    edit: 'edit_account'},
             controllers: {confirmations: 'users/confirmations',
                               passwords: 'users/passwords',
                           registrations: 'users/registrations',
                                sessions: 'users/sessions',
                                 unlocks: 'users/unlocks'}

  devise_scope :user do
    get '/cancel_account',  to: 'users/registrations#cancel_account',  as: :cancel_account
    get '/change_password', to: 'users/registrations#change_password', as: :change_password
    get '/create_username', to: 'users/registrations#create_username', as: :create_username
  end
  
end
