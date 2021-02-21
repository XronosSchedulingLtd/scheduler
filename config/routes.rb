Rails.application.routes.draw do

  #
  #  This line is a little messy, but I can find no way of expressing
  #  it using the "resources" syntax.
  #
  post '/ad_hoc_domain_subjects/:ad_hoc_domain_subject_id/ad_hoc_domain_staffs/:ad_hoc_domain_staff_id/ad_hoc_domain_pupil_courses',
       to: 'ad_hoc_domain_pupil_courses#create',
       as: 'ad_hoc_domain_subject_ad_hoc_domain_staff_ad_hoc_domain_pupil_courses'

  resources :ad_hoc_domain_pupil_courses, only: [:update, :destroy]

  resources :ad_hoc_domains do
    resources :ad_hoc_domain_cycles, shallow: true do
      member do
        put :set_as_default
      end
      resources :ad_hoc_domain_subjects, shallow: true
      resources :ad_hoc_domain_staffs, shallow: true
    end
    member do
      get :edit_controllers
      patch :add_controller
      patch :remove_controller
    end
  end

  resources :user_profiles do
    resources :users
    member do
      post :do_clone
    end
  end

  resources :pre_requisites

  resources :journals, only: [:index, :show]

  resources :event_collections, only: [:index, :destroy, :show] do
    member do
      put :reset
    end
  end

  resources :user_forms, shallow: true do
    resources :user_form_responses
    get :autocomplete_user_form_name, :on => :collection
  end

  resources :user_form_responses do
    resources :comments, shallow: true
  end

#  resources :periods, only: [:index]

  resources :notifiers

  resources :requests do
    resources :commitments
    member do
      get :candidates
      put :fulfill
      put :unfulfill
      put :increment
      put :decrement
      put :dragged
      put :reconfirm
    end
  end

  resources :exam_cycles do
    member do
      put :scan_rooms
      put :generate_all
    end
    resources :proto_events do
      member do
        post :generate
      end
    end
  end

  resources :proto_events, only: [:split] do
    member do
      post :split
    end
  end

  #
  #  I don't seem to be able to achieve this by means of the shallow
  #  modifier, because it recurses into inner nestings and can't
  #  be turned off again.  I can't make things properly shallow because
  #  Backbone doesn't work that way.
  #
  resources :rota_template_types do
    resources :rota_templates, except: [:show, :edit, :update, :destroy]
  end

  resources :rota_templates, only: [:show, :update, :destroy] do
    resources :rota_slots
    member do
      post :do_clone
      get :new_from
      get :slots
    end
  end

#  resources :rota_template_types, shallow: true do
#    resources :rota_templates
#      resources :rota_slots
#      member do
#        post :do_clone
#      end
#    end
#  end

  resources :settings

  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  get 'sessions/new'

  get 'sessions/create'

  get 'sessions/destroy'

  get 'sessions/demo_login'
 
  put 'sessions/become/:user_id' => 'sessions#become', as: :become

  put 'sessions/revert' => 'sessions#revert', as: :revert

  get '/ical/:id' => 'elements#ical'

  resources :locationaliases

  resources :groups do
    resources :memberships, shallow: true do
      member do
        put :terminate
      end
    end
    member do
      get :members
      get :schedule
      get :scheduleresources
      get :scheduleevents
      post :do_clone
      post :flatten
      post :reinstate
    end
    collection do
      get :autocomplete_group_name
      get :autocomplete_old_group_name
      get :autocomplete_resourcegroup_name
      get :autocomplete_owned_group_name
      get :autocomplete_old_owned_group_name
    end
  end

  resources :freefinders do
    member do
      post :add_element
      post :remove_element
      put :reset
    end
  end

  resources :tutorgroups

  resources :locations do
    resources :locationaliases, only: [:new, :create]
    collection do
      get :tree
      get :autocomplete_location_name
    end
  end

  resources :pupils

  resources :properties

  resources :services

  resources :subjects

  resources :users do
    get :autocomplete_user_name, :on => :collection
    get :pp, :on => :collection
    resources :filters, only: [:edit, :update]
    resources :events, only: [:index]
    resources :requests, only: [:index]
    resources :emails, only: [:index]
    #
    #  One would not normally make :destroy and :edit for concerns
    #  subsidiary to users, but we do it to distinguish such
    #  requests from those for the current user.  It's a completely
    #  different area of dialogues.
    #
    resources :concerns, only: [:create, :destroy, :edit]
    resources :concern_sets do
      member do
        put :select
      end
      collection do
        get :refresh
      end
    end
    resources :user_files do
      collection do
        get :index
        post :upload
      end
    end
  end
  resources :user_files, only: [:index, :show, :destroy]

  resources :commitments do
    member do
      put :approve
      put :reject
      put :noted
      put :ajaxapprove
      put :ajaxreject
      put :ajaxnoted
    end
  end

  post '/commitments/:commitment_id/coverwith/:id', to: 'covers#coverwith'

  resources :staffs

  resources :events do
    resources :notes, shallow: true
    resources :requests
    resources :wrappers, only: [:new, :create]
    resources :cloners, only: [:new, :create]
    resources :event_collections
    member do
      get :shownotes
      get :canceledit
      get :coverrooms
      put 'moved'
      post :clone
      post :upload
    end
    get :search, :on => :collection
  end

  resources :days do
    get :index, :on => :collection
  end

  resources :datasources

  resources :eventsources

  resources :eventcategories do
    get :autocomplete_eventcategory_name, :on => :collection
  end

  resources :interests

  resources :concerns do
    member do
      put :flipped
    end

    collection do
      get :sidebar
    end

  end

  resources :itemreports

  resources :elements do
    resources :promptnotes, shallow: true
    resources :journal_entries, only: [:index]
    resources :commitments, only: [:index]
    resources :requests, only: [:index]
    resources :form_reports, only: [:create]
    collection do
      get :autocomplete_element_name
      get :autocomplete_staff_element_name
      get :autocomplete_pupil_element_name
      get :autocomplete_group_element_name
      get :autocomplete_property_element_name
      get :autocomplete_location_element_name
      get :autocomplete_subject_element_name
      get :autocomplete_direct_add_element_name
      get :autocomplete_viewable_element_name
      get :autocomplete_tutorgroup_element_name
    end
    member do
      get :ical
      get :timetable
      get :timetables
    end
  end

  resources :item do
    resources :days do
      get :index, :on => :collection
    end
  end

  get 'schedule/show'
  get 'schedule/events'
  put 'schedule/change_time'

#  resources :imports

  get 'imports/index'
  post 'imports/upload'
  delete 'imports/delete'
  get 'imports/check_file'
  post 'imports/commit_file'

  resources :eras

  resources :emails, only: [:index, :show]

  get 'agenda' => 'agendas#show'
  get 'agenda/events' => 'agendas#events'

  root 'schedule#show'

  mount PublicApi::Engine, at: :api

  #
  #  Extra route for test environment only.  Allows quick login
  #  for integration tests where we're not actually testing
  #  the login functionality.
  #
  if Rails.env.test?
    put 'sessions/test_login' => 'sessions#test_login', as: :test_login
  end

  if Rails.env.production?
    match '*path', via: :all, to: 'pages#error_404'
  end
end
