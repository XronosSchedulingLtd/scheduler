PublicApi::Engine.routes.draw do
  get '/login', to: 'sessions#login'

  resources :elements, only: [:index]
end
