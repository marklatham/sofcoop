Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL [Domain-Specific Language] available within this file, see http://guides.rubyonrails.org/routing.html
  
  root 'visitors#index'
  
end
