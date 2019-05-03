PublicApi::Engine.routes.draw do
  get '/login', to: 'sessions#login'
  get '/logout', to: 'sessions#logout'

  resources :elements, only: [:index, :show] do
    resources :requests, only: [:index]
    resources :commitments, only: [:index]
  end

  resources :events, only: [:show, :create, :destroy] do
    member do
      post :add
    end
  end

  resources :commitments, only: [:destroy]
  resources :requests, only: [:destroy]
  resources :eventcategories, only: [:index, :show]

#  resources :pupils, only: [:index]
end
