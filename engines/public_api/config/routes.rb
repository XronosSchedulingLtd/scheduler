PublicApi::Engine.routes.draw do
  get '/login', to: 'sessions#login'
  get '/logout', to: 'sessions#logout'

  resources :elements, only: [:index, :show] do
    resources :events, only: [:index]
  end
#  resources :pupils, only: [:index]
end
