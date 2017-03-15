Rails.application.routes.draw do

  root 'visitors#index'
  
  ### POSTS: #######################
  
  get    '/@:username/:slug',        to: 'posts#show',         as: :post
  get    '/@:username/:slug/edit',   to: 'posts#edit',         as: :edit_post
  delete '/@:username/:slug/delete', to: 'posts#destroy',      as: :delete_post
  
  resources :posts, except: [:show, :edit, :destroy]
  
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
    get '/delete_avatar',   to: 'users/registrations#delete_avatar',   as: :delete_avatar
  end
  
end
