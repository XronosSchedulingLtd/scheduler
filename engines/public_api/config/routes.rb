PublicApi::Engine.routes.draw do
  get '/login', to: 'sessions#login'
  get '/logout', to: 'sessions#logout'

  resources :sessions, only: [:update] do
    member do
      put :revert
      get :whoami
    end
  end

  resources :elements, only: [:index, :show] do
    resources :requests, only: [:index]
    resources :commitments, only: [:index]
  end

  resources :events, only: [:show, :create, :update, :destroy] do
    resources :notes, shallow: true
    member do
      post :add
    end
  end

  resources :commitments, only: [:destroy]
  resources :requests, only: [:destroy]
  resources :eventcategories, only: [:index, :show]

  resources :users, only: [:index]

end
