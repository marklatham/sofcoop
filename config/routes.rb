Rails.application.routes.draw do

  root 'channels#home'
  
  ### TAGS: ########################

  resources :tags,     only: :index
  get    '/tags/:slug',                     to: 'tags#show',                as: :tag
  get    '/@@:channel_slug/tags/:slug', to: 'tags#channel_tag',         as: :channel_tag
  get    '/@:username/tags/:slug',      to: 'tags#author_tag',          as: :author_tag
  
  ### CHANNELS: ####################
  
  get       '/@@:channel_slug',             to: 'channels#show',            as: :channel
  get       '/@@:channel_slug/posts',       to: 'channels#posts',           as: :channel_posts
  post      'votes/vote_for_channel',       to: 'votes#vote_for_channel',   as: :vote_for_channel
  get       '/past-shares',                 to: 'channels#past_shares',     as: :past_shares
  get       '/@@:channel_slug/past-shares', to: 'channels#past_shares1',    as: :past_shares1
  resources :channels, except: [:show]
  
  ### IMAGES: ######################
  
  get    '/images/@:username/:slug.:ext/data',       to: 'images#data',     as: :image_data
  get    '/images/@:username/:slug.:ext/edit',       to: 'images#edit',     as: :edit_image
  delete '/images/@:username/:slug.:ext/delete',     to: 'images#destroy',  as: :delete_image
  get    '/images/@:username/:slug(.:version).:ext', to: 'images#show',     as: :image
  get    '/images/@:username',                   to: 'images#user_images',  as: :user_images
  
  get    '/avatars/@:username.:ext',             to:
         redirect('https://sofcoop.s3-us-west-2.amazonaws.com/avatars/%{username}.%{ext}')
  
  get    '/channels/@@:channel_slug.:ext',       to:
          redirect('https://sofcoop.s3-us-west-2.amazonaws.com/channels/%{channel_slug}.%{ext}')
  
  resources :images, except: [:show, :edit, :destroy]
  
  ### POSTS: #######################
  
  get    '/@@:channel_slug/@:username/:slug', to: 'posts#show',       as: :channel_post
  get    '/@:username/:slug',                 to: 'posts#show',       as: :post
  get    '/@:username/:slug/markdown',        to: 'posts#markdown'
  get    '/@@:channel_slug/@:username/:slug/markdown', to: 'posts#markdown'
  get    '/@:username/:slug/edit',            to: 'posts#edit',       as: :edit_post
  delete '/@:username/:slug/delete',          to: 'posts#destroy',    as: :delete_post
  get    '/posts/@:username',                 to: 'posts#user_posts', as: :user_posts

  resources :posts,    except: [:show, :edit, :destroy]
  resources :posts do
    collection do
      match 'search' => 'posts#search', via: [:get, :post], as: :search
    end
  end
  resources :comments, only:   [:create, :update, :destroy]
  
  ### USERS: #######################
  
  get    '/@:username',                  to: 'users#show',       as: :user
  get    '/users',                       to: 'users#index',      as: :users

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
                      omniauth_callbacks: 'users/omniauth_callbacks'}

  devise_scope :user do
    get '/cancel_account',  to: 'users/registrations#cancel_account',  as: :cancel_account
    get '/change_password', to: 'users/registrations#change_password', as: :change_password
    get '/delete_avatar',   to: 'users/registrations#delete_avatar',   as: :delete_avatar
  end
  
  ### VANITY SLUGS: ##################
  
  get    '/:vanity_slug',          to: 'posts#show',                   as: :vanity
  get    '/:vanity_slug/markdown', to: 'posts#markdown'
  
end
