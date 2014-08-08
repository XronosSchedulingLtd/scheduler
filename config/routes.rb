Rails.application.routes.draw do
  resources :settings

  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  get 'sessions/new'

  get 'sessions/create'

  get 'sessions/destroy'

  get '/ical/:id' => 'staffs#ical'

  resources :locationaliases

  resources :groups

  resources :tutorgroups

  resources :locations

  resources :pupils

  resources :users

  resources :commitments

  resources :staffs do
    member do
      get :ical
    end
  end

  resources :events do
    member do
      put 'moved'
    end
  end

  resources :eventsources

  resources :eventcategories

  resources :interests

  resources :elements do
    get :autocomplete_element_name, :on => :collection
  end

  get 'schedule/show'
  get 'schedule/events'
  put 'schedule/change_time'

#  resources :imports

  get 'imports/index'
  post 'imports/upload'
  delete 'imports/delete'
  get 'imports/check_csv'
  post 'imports/commit_csv'

  resources :eras

  root 'schedule#show'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
