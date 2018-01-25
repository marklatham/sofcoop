Rails.application.routes.draw do

  root 'channels#home'
  
  ### TAGS: ########################

  resources :tags,     only: :index
  
  ### CHANNELS: ####################
  
  get    '/@@:channel_slug',                           to: 'channels#show',          as: :channel
  post   'votes/vote_for_channel',                     to: 'votes#vote_for_channel', as: :vote_for_channel
  get    '/past-shares',                               to: 'channels#past_shares',   as: :past_shares
  get    '/@@:channel_slug/past-shares',               to: 'channels#past_shares1',  as: :past_shares1
  resources :channels, except: [:show]
  
  ### IMAGES: ######################
  
  get    '/images/@:username/:image_slug.:ext/data',       to: 'images#data',        as: :image_data
  get    '/images/@:username/:image_slug.:ext/edit',       to: 'images#edit',        as: :edit_image
  delete '/images/@:username/:image_slug.:ext/delete',     to: 'images#destroy',     as: :delete_image
  get    '/images/@:username/:image_slug(.:version).:ext', to: 'images#show',        as: :image
  get    '/images/@:username',                             to: 'images#user_images', as: :user_images
  
  get    '/avatars/@:username.:ext',                       to:
         redirect('https://sofcoop.s3-us-west-2.amazonaws.com/avatars/%{username}.%{ext}')
  
  get    '/channels/@@:channel_slug.:ext',                 to:
         redirect('https://sofcoop.s3-us-west-2.amazonaws.com/channels/%{channel_slug}.%{ext}')
  
  resources :images, except: [:show, :edit, :destroy]
  
  ### POST LISTINGS: ###############

  get    '(/@@:channel_slug)(/@:username)(/tags/:tag_slug)/posts', to: 'post_listings#index',   as: :posts
  match  '(/@@:channel_slug)(/@:username)(/tags/:tag_slug)/posts/search' => 'post_listings#search',
                                                                  via: [:get, :post],           as: :search_posts
  get    '(/@@:channel_slug)/@:username/:post_slug/history',       to: 'post_listings#history'
  
  ### POSTS: #######################

  get    '(/@@:channel_slug)/@:username/:post_slug',               to: 'posts#show',            as: :post
  delete '/@:username/:post_slug/delete',                          to: 'posts#destroy',         as: :delete_post
  get    '(/@@:channel_slug)/@:username/:post_slug/approve',       to: 'posts#approve',         as: :approve_post
  get    '(/@@:channel_slug)/@:username/:post_slug/markdown',      to: 'posts#markdown'
  get    '(/@@:channel_slug)/@:username/:post_slug/history/:item_version_id',          to: 'posts#version'
  get    '(/@@:channel_slug)/@:username/:post_slug(/history/:item_version_id)/edit',   to: 'posts#edit', as: :edit_post
  get    '(/@@:channel_slug)/@:username/:post_slug/history/:item_version_id/markdown', to: 'posts#version_markdown'

  resources :posts,    except: [:index, :show, :edit, :destroy]
  resources :comments, only:   [:create, :update, :destroy]
  
  ### USERS: #######################
  
  get    '/@:username',               to: 'users#show',     as: :user
  resources :users, except: [:show]   # Admin interface for user management.

  devise_for :users, path: '',
             path_names:  {      sign_up: 'register',
                                 sign_in: 'login',
                                sign_out: 'logout',
                                    edit: 'edit_account'},
             controllers: {confirmations: 'users/confirmations',
                               passwords: 'users/passwords',
                           registrations: 'users/registrations',
                                sessions: 'users/sessions',
                                 unlocks: 'users/unlocks',
                      omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    get '/cancel_account',            to: 'users/registrations#cancel_account',      as: :cancel_account
    get '/change_password',           to: 'users/registrations#change_password',     as: :change_password
    get '/delete_avatar',             to: 'users/registrations#delete_avatar',       as: :delete_avatar
  end
  
  ### VANITY SLUGS: ##################
  
  get    '/:vanity_slug',                                   to: 'posts#show',             as: :vanity
  get    '/:vanity_slug/markdown',                          to: 'posts#markdown'
  get    '/:vanity_slug/history',                           to: 'post_listings#history'
  get    '/:vanity_slug/history/:item_version_id',          to: 'posts#version'
  get    '/:vanity_slug/history/:item_version_id/markdown', to: 'posts#version_markdown'
  
end
