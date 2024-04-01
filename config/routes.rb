Rails.application.routes.draw do
  # Existing routes

  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  }, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  get 'current_user', to: 'current_user#index'

  resources :requests, only: [:index, :show] do
    resources :messages, only: [:index, :create]
    
    member do
      patch 'mark-as-completed', to: 'requests#mark_as_completed'
      post 'republish', to: 'requests#republish'
      post 'volunteer', to: 'requests#volunteer'
      # Adding a route for initiating messaging for a request
      get 'initiate-message', to: 'messages#new', as: :initiate_message
    end

    collection do
      get 'active', to: 'requests#all_active_requests'
      get 'unfulfilled-count', to: 'requests#unfulfilled_count'
    end
  end

  get '/users/messageable', to: 'users#messageable'

  resources :users do
    resources :requests, only: [:create, :show, :update] do
      member do
        patch 'mark-as-completed', to: 'requests#mark_as_completed'
        post 'republish', to: 'requests#republish'
      end
    end

    member do
      get 'my-requests', to: 'requests#my_requests'
      get 'volunteered-jobs', to: 'volunteerings#volunteered_jobs'
    end
  end

  resources :volunteerings do
  member do
    patch 'mark-as-completed', to: 'volunteerings#mark_as_completed'
  end
end

  # You might need to define a root or other routes here
  # root "some_controller#some_action"
end


