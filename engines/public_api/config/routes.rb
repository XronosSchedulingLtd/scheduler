PublicApi::Engine.routes.draw do
  get '/login', to: 'sessions#login'
  get '/logout', to: 'sessions#logout'

  put 'sessions/become/:user_id' => 'sessions#become', as: :become

  put 'sessions/revert' => 'sessions#revert', as: :revert

  get 'sessions/whoami' => 'sessions/whoami', as: :whoami

  resources :elements, only: [:index, :show] do
    resources :requests, only: [:index]
    resources :commitments, only: [:index]
  end

  resources :events, only: [:show, :create, :destroy] do
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
