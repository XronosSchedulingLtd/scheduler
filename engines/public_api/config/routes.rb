PublicApi::Engine.routes.draw do
  get '/login', to: 'sessions#login'
  get '/logout', to: 'sessions#logout'

  resources :elements, only: [:index, :show] do
    resources :requests, only: [:index]
    resources :commitments, only: [:index]
  end

  resources :events, only: [:create]

#  resources :pupils, only: [:index]
end
