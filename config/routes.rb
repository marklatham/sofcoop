Rails.application.routes.draw do

  root 'visitors#index'
  
  ### IMAGES: ######################
  
  get    '/images/@:username/:slug.:ext/data',   to: 'images#data',     as: :image_data
  get    '/images/@:username/:slug.:ext/edit',   to: 'images#edit',     as: :edit_image
  delete '/images/@:username/:slug.:ext/delete', to: 'images#destroy',  as: :delete_image
  
  get    '/images/@:username/:slug.:ext',        to:
  redirect('https://sofcoop.s3-us-west-2.amazonaws.com/images/%{username}/%{slug}.%{ext}')
  get    '/avatars/@:username.:ext',             to:
  redirect('https://sofcoop.s3-us-west-2.amazonaws.com/avatars/%{username}.%{ext}')
  
  resources :images, except: [:show, :edit, :destroy]
  
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
